{
  ...
}: {
  # WSL2 网络由 Windows 侧管理，不用 NetworkManager
  networking.hostName = "mioha-wsl";
  networking.firewall.enable = false;
  networking.nftables.enable = false;
}
