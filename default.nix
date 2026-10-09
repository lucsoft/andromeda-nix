# `nix-build` here, or callPackage ./package.nix from your own config.
{ pkgs ? import <nixpkgs> { } }:

pkgs.callPackage ./package.nix { }
