{
  pkgs,
  ...
}: {
  # 保留 xserver: 仅为其 XKB 键盘配置供 XWayland 使用，不启图形 X 会话
  services.xserver.enable = true;
  services.gvfs.enable = true;
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
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };
}
