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
    polkit_gnome
    dnsmasq
    libxkbcommon
    xwayland-satellite
   ];
}
