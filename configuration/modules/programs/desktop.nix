{ 
  pkgs,
  inputs,
  ...
}: {
  services.xserver.enable = true;
  services.gvfs.enable = true;
  services.displayManager.ly.enable = true;
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  programs.firefox.enable = true;
  programs.mango.enable = true;

  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [pkgs.xdg-desktop-portal-gtk];

    wlr.enable = true;
    wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel -d -l 10 -p 'Select display to share: '";
    };
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };
}
