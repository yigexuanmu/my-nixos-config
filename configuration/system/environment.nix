{
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];

  environment.systemPackages = with pkgs; [
    gcc
    nh
    git
    polkit_gnome
    dnsmasq
    libxkbcommon
    wayland-protocols
    libdecor
    xwayland-satellite
    distrobox
    gamescope
  ];
}
