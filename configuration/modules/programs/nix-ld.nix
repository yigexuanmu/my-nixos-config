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

    # OpenGL / 图形
    libGL
    libGLU

    # X11 基础
    libX11
    libXext
    libXrandr
    libXcursor
    libXi
    libXinerama
    libxkbcommon

    # 音频
    libpulseaudio
    alsa-lib

    # 其他 Proton/Wine 常需要的
    SDL2
    gnutls
    freetype
    fontconfig
    dbus
    libusb1
    ];
  };
}
