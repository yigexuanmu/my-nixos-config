{
  pkgs,
  ...
}: {
  # 移除了 wayland/x11 相关 (xwayland-satellite、polkit_gnome 等)、gamescope、waydroid-helper
  environment.systemPackages = with pkgs; [
    gcc
    nh
    git
    dnsmasq
    distrobox
  ];
}
