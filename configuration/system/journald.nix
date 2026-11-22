# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{ ... }: {
  services.journald.settings = {
    Journal = {
      SystemMaxUse = "1G";
      SystemMaxFileSize = "100M";
      RuntimeMaxUse = "256M";
    };
  };
}
