{
  pkgs,
  ...
}: {
  networking.hostName = "mioha-nix";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  networking.nftables.enable = false;
  environment.systemPackages = with pkgs; [dnsmasq];

  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };
}
