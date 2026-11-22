# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/modules/virtualisation/droidloom.nix（要求 uid = 1000）
#     - configuration/modules/virtualisation/libvirtd.nix（libvirtd 用户组）
#     - configuration/modules/virtualisation/podman.nix（podman 用户组）
#     - configuration/device/hardware/nvidia.nix（video 用户组）
#     - configuration/home/programs.nix（自动：共享 /home/mioha）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  users.users.mioha = {
    isNormalUser = true;
    uid = 1000; # droidloom 模块要求显式 uid
    home = "/home/mioha";
    extraGroups = ["wheel" "networkmanager" "libvirtd" "kvm" "input" "audio" "uinput" "podman" "video"];
  };
}
