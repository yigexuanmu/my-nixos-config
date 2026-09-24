{ 
  pkgs,
  inputs,
  ...
}: {
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
