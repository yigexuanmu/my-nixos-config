{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    nwg-look
    wf-recorder
    slurp
    grim
    imv
    wl-clipboard
    pywalfox-native
    libnotify
    nautilus
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
    # thunar相关
    thunar
    tumbler
    ffmpegthumbnailer
    poppler
    file-roller
    gvfs
    thunar-archive-plugin
    gnome-keyring
    thunar-volman
    webp-pixbuf-loader
    icoextract
    python314Packages.pillow
    # 壁纸引擎
    inputs.we-layerd.packages.x86_64-linux.default
  ];
}
