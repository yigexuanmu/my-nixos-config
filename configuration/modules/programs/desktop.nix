{
  pkgs,
  ...
}: {
  # 保留 xserver: XKB 键盘配置供 XWayland 使用，SDDM 的 X11 greeter 也依赖它
  services.xserver.enable = true;
  services.gvfs.enable = true;
  services.displayManager.sddm.enable = true;
  programs.firefox.enable = true;
  programs.denial.enable = true;
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
