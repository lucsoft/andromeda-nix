# andromeda-nix

Nix packaging for [Andromeda](https://tryandromeda.dev), a JS/TS runtime built
on [Nova](https://trynova.dev) that runs TypeScript without transpiling it.

Not affiliated with upstream. A weekly workflow picks up new releases and only
pushes if the package builds and the binary runs.

## Binary cache

Building this takes a while (wgpu, winit, a bundled SQLite, LTO). Point Nix at
the cache first:

```nix
nix.settings = {
  substituters = [ "https://andromeda-nix.cachix.org" ];
  trusted-public-keys = [
    "andromeda-nix.cachix.org-1:DEWHc3Ls1TK60gCMDnztXLcd5vE45As8QMP8Ro/cbaE="
  ];
};
```

On non-NixOS, the same two lines go into `/etc/nix/nix.conf` as
`extra-substituters` and `extra-trusted-public-keys`, or run
`cachix use andromeda-nix`.

## Use it

Try it without installing anything:

```
nix run github:lucsoft/andromeda-nix -- run script.ts
```

As a flake input:

```nix
{
  inputs.andromeda.url = "github:lucsoft/andromeda-nix";

  # in your configuration
  environment.systemPackages = [ andromeda.packages.${system}.default ];
}
```

There is an `overlays.default` if you would rather have `pkgs.andromeda`.

Flakes are not required. `package.nix` takes nothing but a `callPackage` scope,
so it works against whatever nixpkgs you already pin:

```nix
andromeda = pkgs.callPackage "${sources.andromeda-nix}/package.nix" { };
```

## Build options

`andromeda-headless` turns the canvas and window features off, and with them
wgpu, winit, Vulkan and fontconfig. That is a 79.7 MiB closure against 114.0,
with nothing left but glibc and the gcc runtime. CI builds it, so it comes from
the cache:

```
nix run github:lucsoft/andromeda-nix#andromeda-headless -- run script.ts
```

Anything finer goes through `override`:

```nix
pkgs.andromeda.override {
  withCanvas = false;    # wgpu, image, cosmic-text
  withWindow = false;    # winit
  withProposals = false; # drops Float16Array, and with it RUSTC_BOOTSTRAP
}
```

Upstream pins these in its dependency declarations rather than exposing them as
features, so the canvas and proposals switches patch a manifest. Only the two
variants CI builds are cached; other combinations compile locally.

## Packaging notes

- Only the `andromeda` binary is installed, none of the other bins upstream
  builds.
- `RUSTC_BOOTSTRAP=1`, because the CLI enables `andromeda-runtime/proposals`,
  which pulls in `nova_vm/proposal-float16array` and so `feature(f16)`, which
  stable rustc rejects. Upstream builds on nightly.
- Linux only. Untested elsewhere.
