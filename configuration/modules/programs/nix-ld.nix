{
  pkgs,
  ...
}: {
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      libffi
      glibc
      vulkan-loader
      mesa
      vulkan-tools
      libGL
      libGLU
      libX11
      libXext
      libXrandr
      libXcursor
      libXi
      libXinerama
      libxkbcommon
      libpulseaudio
      alsa-lib
      SDL2
      gnutls
      freetype
      fontconfig
      dbus
      libusb1
    ];
  };
}
