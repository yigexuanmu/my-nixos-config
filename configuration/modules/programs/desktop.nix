{ 
  pkgs,
  inputs,
  ...
}: {
  services.xserver.enable = true;
  services.displayManager.ly.enable = true;
  services.gvfs.enable = true;
  programs.niri = {
    enable = true;
    package = inputs.niri-glass.packages.x86_64-linux.default;
  };
}
