# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/pkgs/tools/networking/clash-party.nix（pkgs.clash-party 的来源）
#     - configuration/modules/packages/clash-party.nix（同一软件包）
# ────────────────────────────────────────────────────────────

{pkgs, ...}: {
  security.wrappers.mihomo-party = {
    owner = "root";
    group = "root";
    capabilities = "cap_net_bind_service,cap_net_raw,cap_net_admin=+ep";
    source = "${pkgs.clash-party}/bin/mihomo-party";
  };
}
