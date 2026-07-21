{
  ...
}: {
  virtualisation.vmware.host = {
    enable = true;
    extraConfig = ''
      mks.enable3d = "TRUE"
      mks.gl.allowUnsupportedDrivers = "TRUE"
      mks.vk.allowUnsupportedDevices = "TRUE"
    '';
  };

  # 禁用透明大页，避免 kcompactd0 高 CPU 占用
  boot.kernelParams = [ "transparent_hugepage=never" ];
}
