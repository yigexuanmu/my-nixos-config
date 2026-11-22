# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：无
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/mioha-main/modules.nix（启用时在此取消注释）
# ────────────────────────────────────────────────────────────

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
