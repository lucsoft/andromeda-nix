{
  description = "Andromeda, a JS/TS runtime powered by Nova";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = final: _prev: {
        andromeda = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (pkgs: rec {
        andromeda = pkgs.callPackage ./package.nix { };

        andromeda-headless =
          (andromeda.override {
            withCanvas = false;
            withWindow = false;
          }).overrideAttrs
            { doCheck = false; };

        default = andromeda;
      });

      checks = forAllSystems (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) andromeda andromeda-headless;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
