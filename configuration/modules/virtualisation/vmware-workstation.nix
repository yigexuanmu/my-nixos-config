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
}
