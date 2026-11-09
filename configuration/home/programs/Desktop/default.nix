{
  pkgs,
  inputs,
  ...
}: let
  # nixpkgs 里的 waybar 是 0.15.0，没有 mango/* 模块；
  # 用 flake 里的上游 master（0.16.0）并打开 -Dmango 编译选项。
  # 上游 flake 的 overlay 负责把 libcava 子项目按 0.16 需要的版本放好。
  waybar = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    mesonFlags = old.mesonFlags ++ ["-Dmango=true"];
  });
in {
  imports = [
    ./cursor.nix
  ];

  home.packages = with pkgs; [
    nwg-look
    imv
    wl-clipboard
    libnotify
    nautilus
    ffmpegthumbnailer
    file-roller
    nautilus-open-any-terminal
    # GStreamer 插件通过 gst_all_1 属性集引用
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-libav
    # Python 包通过 python3Packages 属性集引用
    python3Packages.pillow
    python3Packages.icoextract
    # 状态栏 / 启动器 / 应用外壳（noctalia + waybar 这一套）
    waybar
    fuzzel
    matugen
    # waybar 脚本会用到的工具
    grim
    slurp
    satty
    swappy
    hyprpicker
    cliphist
    wl-screenrec
    wf-recorder
    wlr-randr
    brightnessctl
    swayosd
    swaynotificationcenter
    wlsunset
    # 主题相关
    papirus-icon-theme
    papirus-folders
    adw-gtk3
    afterglow-cursors-recolored
    # qt/gtk相关
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    gtk3
    gtk4
    gnome-keyring
    ddcutil
    gnome-clocks
    gnome-calendar
    xdg-user-dirs
    adwaita-fonts
    lxgw-wenkai-screen
    font-awesome_7
  ];
}
