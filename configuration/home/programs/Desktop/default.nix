# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：
#     - configuration/home/programs/Desktop/cursor.nix
#     - configuration/pkgs/tools/desktop/waywallen-layer-shell/default.nix
#   相关（语义关联）：
#     - configuration/home/programs/Desktop/fuzzel/default.nix（自动：使用 fuzzel）
#     - configuration/home/programs/Desktop/waybar/default.nix（自动：使用 waybar）
#     - configuration/modules/programs/desktop.nix（自动：使用 desktop）
# ────────────────────────────────────────────────────────────

{
  pkgs,
  ...
}: {
  imports = [
    ./cursor.nix
  ];

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
    matugen
    wlsunset
    swayosd
    swaynotificationcenter
    gnome-clocks
    gnome-calendar
    wl-screenrec
    wlr-randr
    xdg-user-dirs
    adwaita-fonts
    lxgw-wenkai-screen
    font-awesome_7

    (pkgs.callPackage ../../../pkgs/tools/desktop/waywallen-layer-shell {})
  ];
}
