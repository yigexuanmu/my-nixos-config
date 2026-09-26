{ pkgs, ... }:
{
  programs.xfconf.enable = true;
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];

  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    xdg-desktop-portal-gtk
    tumbler
    ffmpegthumbnailer
    poppler-utils
    file-roller
    gnome-keyring
    webp-pixbuf-loader
    icoextract
    python3Packages.pillow
  ];
}
