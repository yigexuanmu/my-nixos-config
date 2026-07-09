{
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];

  environment.systemPackages = with pkgs; [
    vscode
    vim
    git
    nh
    gcc
    polkit_gnome
    dnsmasq
    libxkbcommon
    wget
    opencode
    fish
    cage
    xwayland-satellite
    adwaita-icon-theme
    morewaita-icon-theme
    papirus-icon-theme
    adw-gtk3
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    afterglow-cursors-recolored
    wineWow64Packages.stagingFull
     kitty
     distrobox
   ];

  environment.etc."os-release".text = ''
    NAME="HarmonyOS"
    VERSION="9.1"
    ID=nixos
    PRETTY_NAME="HarmonyOS X NEXT Ultra Pro Max Plus Turbo X100 Elite 非凡大师 GT 特别专享版"
  '';
}
