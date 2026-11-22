# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/home/mango-session.nix（mango 会话 target / portal）
#     - configuration/home/programs/Desktop/mango/default.nix
#     - configuration/home/programs/Desktop/fuzzel/default.nix（portal chooser）
#     - configuration/modules/services/flatpak.nix（xdg portal 已迁移至此）
# ────────────────────────────────────────────────────────────

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
