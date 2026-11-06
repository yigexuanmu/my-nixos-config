{
  pkgs,
  ...
}: {
  imports = [
    ./cursor.nix
  ];

  home.packages = with pkgs; [
    nwg-look
    imv
    wl-clipboard
    libnotify
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
