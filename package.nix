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

  # Both crates come from one git checkout and share a hash.
  cargoLock = {
    lockFile = "${finalAttrs.src}/Cargo.lock";
    outputHashes = {
      "nova_vm-1.0.0" = "sha256-tw/PwoaquKzsCDQjsTrlIAdnzCBYaf8iOpHF/GwB2LU=";
      "small_string-1.0.0" = "sha256-tw/PwoaquKzsCDQjsTrlIAdnzCBYaf8iOpHF/GwB2LU=";
    };
  };

  postPatch =
    lib.optionalString (!withCanvas) ''
      substituteInPlace Cargo.toml --replace-fail '"canvas",' ""
    ''
    + lib.optionalString (!withProposals) ''
      substituteInPlace crates/cli/Cargo.toml --replace-fail '"proposals",' ""
    '';

  buildNoDefaultFeatures = !withWindow;

  # proposals -> nova_vm/proposal-float16array -> feature(f16), rejected by stable rustc.
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

  # wgpu and winit dlopen their backends.
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
