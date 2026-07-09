{
  ...
}: {
  networking.hostName = "mioha-nix";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  networking.nftables.enable = false;
}
