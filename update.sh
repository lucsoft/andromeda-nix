#!/usr/bin/env bash
set -euo pipefail

repo=tryandromeda/andromeda
pkg="$(dirname "$0")/package.nix"

latest=$(curl -fsS "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$pkg")

if [[ "$latest" == "$current" ]]; then
  echo "already at $current"
  exit 0
fi
echo "$current -> $latest"

src_hash=$(nix-prefetch-url --unpack --type sha256 \
  "https://github.com/$repo/archive/refs/tags/$latest.tar.gz" 2>/dev/null | tail -1)
src_hash=$(nix-hash --to-sri --type sha256 "$src_hash")

sed -i "s|^  version = \".*\";$|  version = \"$latest\";|" "$pkg"
sed -i "0,/hash = \"sha256-[^\"]*\";/s||hash = \"$src_hash\";|" "$pkg"

lock=$(mktemp)
curl -fsS "https://raw.githubusercontent.com/$repo/$latest/Cargo.lock" -o "$lock"

declare -A rev_hash
entries=""
while read -r name version source; do
  rev=${source##*rev=}
  rev=${rev%%#*}
  url=${source#git+}
  url=${url%%\?*}

  if [[ -z "${rev_hash[$rev]:-}" ]]; then
    echo "prefetching $url at $rev" >&2
    # --fetch-submodules is required: nova carries the test262 submodule.
    rev_hash[$rev]=$(nix-prefetch-git --quiet --fetch-submodules --url "$url" --rev "$rev" | jq -r .hash)
  fi
  entries+="      \"$name-$version\" = \"${rev_hash[$rev]}\";"$'\n'
done < <(awk '
  /^\[\[package\]\]/ { name=""; version=""; source="" }
  /^name = / { gsub(/"/, "", $3); name=$3 }
  /^version = / { gsub(/"/, "", $3); version=$3 }
  /^source = "git\+/ { gsub(/"/, "", $3); print name, version, $3 }
' "$lock")

perl -0pi -e "s|    outputHashes = \{\n.*?    \};|    outputHashes = {\n$entries    };|s" "$pkg"

rm -f "$lock"
echo "package.nix now at $latest"
