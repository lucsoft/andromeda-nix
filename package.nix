{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libffi,
  fontconfig,
  libxkbcommon,
  wayland,
  vulkan-loader,
  xorg,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "andromeda";
  version = "0.1.14";

  src = fetchFromGitHub {
    owner = "tryandromeda";
    repo = "andromeda";
    tag = finalAttrs.version;
    hash = "sha256-NFhUy+hqvr9bv/tRu62zdtJGIdIxV09LPInhWXZfTrs=";
  };

  # Both crates come out of one git checkout, so they share one hash.
  cargoLock = {
    lockFile = "${finalAttrs.src}/Cargo.lock";
    outputHashes = {
      "nova_vm-1.0.0" = "sha256-tw/PwoaquKzsCDQjsTrlIAdnzCBYaf8iOpHF/GwB2LU=";
      "small_string-1.0.0" = "sha256-tw/PwoaquKzsCDQjsTrlIAdnzCBYaf8iOpHF/GwB2LU=";
    };
  };

  # The CLI enables andromeda-runtime/proposals, which pulls in
  # nova_vm/proposal-float16array and so `feature(f16)`, which stable rustc
  # rejects. Upstream builds on nightly.
  env.RUSTC_BOOTSTRAP = 1;

  cargoBuildFlags = [
    "-p" "andromeda"
    "--bin" "andromeda"
  ];

  cargoTestFlags = [
    "-p" "andromeda"
    "-p" "andromeda-core"
    "-p" "andromeda-runtime"
  ];

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    libffi
    fontconfig
    libxkbcommon
    wayland
    vulkan-loader
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
  ];

  meta = {
    description = "JS/TS runtime powered by Nova, with no transpilation";
    homepage = "https://tryandromeda.dev";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.linux;
    mainProgram = "andromeda";
  };
})
