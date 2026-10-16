{
  pkgs,
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
    waybar
    fuzzel
    satty
    swappy
    hyprpicker
    ddcutil
    cliphist
    waypaper
    matugen
    wlsunset
    swayosd
    swaynotificationcenter
    hyprlock
    gnome-clocks
    gnome-calendar
    wl-screenrec
    wlr-randr
    xdg-user-dirs
    adwaita-fonts
    lxgw-wenkai-screen
    font-awesome_7
  ];
}
