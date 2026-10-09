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
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  # Upstream pins these in its dependency declarations instead of exposing
  # them as features of the CLI crate, so switching one off patches a manifest.
  withCanvas ? true,
  withWindow ? true,
  withProposals ? true,
}:

let
  needsGpu = withCanvas || withWindow;

  gpuLibs =
    lib.optionals needsGpu [ vulkan-loader ]
    ++ lib.optionals withWindow [
      libxkbcommon
      wayland
    ];
in

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

  # replace-fail, so an upstream reshuffle breaks the build instead of
  # quietly handing back the defaults.
  postPatch =
    lib.optionalString (!withCanvas) ''
      substituteInPlace Cargo.toml --replace-fail '"canvas",' ""
    ''
    + lib.optionalString (!withProposals) ''
      substituteInPlace crates/cli/Cargo.toml --replace-fail '"proposals",' ""
    '';

  # window is the CLI crate's only default feature.
  buildNoDefaultFeatures = !withWindow;

  # proposals reaches nova_vm/proposal-float16array and so `feature(f16)`,
  # which stable rustc rejects. Upstream builds on nightly.
  env = lib.optionalAttrs withProposals { RUSTC_BOOTSTRAP = 1; };

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

  buildInputs =
    [ libffi ]
    ++ lib.optionals withCanvas [ fontconfig ]
    ++ gpuLibs
    ++ lib.optionals withWindow [
      libx11
      libxcursor
      libxi
      libxrandr
    ];

  # winit and wgpu dlopen their backends, so the linker never records them.
  postFixup = lib.optionalString needsGpu ''
    patchelf --add-rpath ${lib.makeLibraryPath gpuLibs} $out/bin/andromeda
  '';

  meta = {
    description = "JS/TS runtime powered by Nova, with no transpilation";
    homepage = "https://tryandromeda.dev";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.linux;
    mainProgram = "andromeda";
  };
})
