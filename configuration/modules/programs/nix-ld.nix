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
      wayland
      libX11
      libXrender
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

  # nix-ld 只补动态库，不补可执行文件。Phira 的输入框/文件选择框在运行时
  # 通过 inputbox / rfd 去 spawn 外部对话框程序（yad 或 zenity），
  # 缺失时日志报 `failed to show input box: Os { code: 2, ... }`。
  environment.systemPackages = [ pkgs.zenity ];
}
