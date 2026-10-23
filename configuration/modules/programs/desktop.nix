{ 
  pkgs,
  inputs,
  ...
}: {
  # 保留 xserver: 仅为其 XKB 键盘配置供 ly/niri/XWayland 使用，不启图形 X 会话
  services.xserver.enable = true;
  services.displayManager.ly.enable = true;
  services.gvfs.enable = true;
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    xdg-desktop-portal-wlr
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  programs.niri = {
    enable = true;
    package = inputs.niri-glass.packages.x86_64-linux.default;
  };
  programs.hyprland = {
    enable = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
  programs.firefox.enable = true;
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };
}
