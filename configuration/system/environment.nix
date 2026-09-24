{
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    gcc
    nh
    git
    distrobox
  ];
}
