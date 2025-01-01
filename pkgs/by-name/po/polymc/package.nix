{
  addDriverRunpath,
  flite,
  gamemode,
  glfw,
  jdk17,
  jdk21,
  jdk8,
  kdePackages,
  lib,
  libGL,
  libX11,
  libXcursor,
  libXext,
  libXrandr,
  libXxf86vm,
  libpulseaudio,
  libusb1,
  mesa-demos,
  openal,
  polymc-unwrapped,
  stdenv,
  symlinkJoin,
  udev,
  vulkan-loader,
  wayland,
  xrandr,

  jdks ? [
    jdk21
    jdk17
    jdk8
  ],
  textToSpeechSupport ? stdenv.hostPlatform.isLinux,
  controllerSupport ? stdenv.hostPlatform.isLinux,
  gamemodeSupport ? stdenv.hostPlatform.isLinux,
  additionalLibs ? [ ],
  additionalPrograms ? [ ],
  msaClientID ? null,
}:

assert lib.assertMsg (
  controllerSupport -> stdenv.hostPlatform.isLinux
) "controllerSupport only has an effect on Linux.";

assert lib.assertMsg (
  textToSpeechSupport -> stdenv.hostPlatform.isLinux
) "textToSpeechSupport only has an effect on Linux.";

let
  polymc' = polymc-unwrapped.override { inherit msaClientID gamemodeSupport; };
in

symlinkJoin {
  name = "polymc-${polymc'.version}";

  paths = [ polymc' ];

  nativeBuildInputs = [ kdePackages.wrapQtAppsHook ];

  buildInputs =
    [ kdePackages.qtbase ]
    ++ lib.optional (
      lib.versionAtLeast kdePackages.qtbase.version "6" && stdenv.hostPlatform.isLinux
    ) kdePackages.qtwayland;

  postBuild = "wrapQtAppsHook";

  qtWrapperArgs =
    let
      runtimeLibs =
        [
          stdenv.cc.cc.lib
          glfw
          openal
          libpulseaudio
          wayland

          # glfw
          libGL
          libX11
          libXcursor
          libXext
          libXrandr
          libXxf86vm

          udev # oshi

          vulkan-loader # VulkanMod's lwjgl
        ]
        ++ lib.optional textToSpeechSupport flite
        ++ lib.optional controllerSupport libusb1
        ++ lib.optional gamemodeSupport gamemode.lib
        ++ additionalLibs;

      runtimePrograms = [
        xrandr
        mesa-demos
      ] ++ additionalPrograms;
    in
    [
      "--prefix POLYMC_JAVA_PATHS : ${lib.makeSearchPath "bin/java" jdks}"
      "--set LD_LIBRARY_PATH ${addDriverRunpath.driverLink}/lib:${lib.makeLibraryPath runtimeLibs}"
      "--prefix PATH : ${lib.makeBinPath runtimePrograms}"
    ];

  inherit (polymc') meta;
}
