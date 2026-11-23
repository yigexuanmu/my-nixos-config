# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/modules/packages/clash-party.nix（clash 相关）
#     - configuration/modules/security/wrappers.nix（clash-party 网络能力）
#     - configuration/modules/services/openssh.nix（防火墙关闭下的 SSH）
# ────────────────────────────────────────────────────────────

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
  };
}
