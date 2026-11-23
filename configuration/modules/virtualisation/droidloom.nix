# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/system/user.nix（要求 uid = 1000）
#     - configuration/device/hardware/nvidia.nix（使用该 GPU）
# ────────────────────────────────────────────────────────────

{
  lib,
  ...
}: {
  services.droidloom = {
    enable = true;
    user = "mioha";
    renderNode = "/dev/dri/renderD128";
    graphicsBackend = "forwarding";
    gpu = "0000:05:00.0"; # RTX 4060 Ti
  };
}
