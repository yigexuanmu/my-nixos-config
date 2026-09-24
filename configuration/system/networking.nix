{
  ...
}: {
  networking.hostName = "mioha-nix";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  networking.nftables.enable = false;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;
}
