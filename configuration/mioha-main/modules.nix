# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：flake.nix
#   下游（本文件引用）：
#     - configuration/modules/programs/steam.nix
#     - configuration/modules/programs/desktop.nix
#     - configuration/modules/programs/neovim.nix
#     - configuration/modules/programs/virt-manager.nix
#     - configuration/modules/programs/nix-ld.nix
#     - configuration/modules/services/flatpak.nix
#     - configuration/modules/services/gnome-keyring.nix
#     - configuration/modules/services/polkit.nix
#     - configuration/modules/services/openssh.nix
#     - configuration/modules/services/sunshine.nix
#     - configuration/modules/services/pipewire.nix
#     - configuration/modules/services/guix.nix
#     - configuration/modules/security/sudo-rs.nix
#     - configuration/modules/security/wrappers.nix
#     - configuration/modules/virtualisation/libvirtd.nix
#     - configuration/modules/virtualisation/podman.nix
#     - configuration/modules/virtualisation/droidloom.nix
#     - configuration/modules/tools/file-map.nix
#     - configuration/modules/services/rime-gram-update.nix
#   相关（语义关联）：
#     - configuration/mioha-main/system.nix（与 system.nix 一起被 flake 引入）
#     - configuration/modules/virtualisation/vmware-workstation.nix（当前在此注释，未启用）
# ────────────────────────────────────────────────────────────

{
  imports = [
    ../modules/programs/steam.nix
    ../modules/programs/desktop.nix
    ../modules/programs/neovim.nix
    ../modules/programs/virt-manager.nix
    ../modules/programs/nix-ld.nix
    ../modules/services/flatpak.nix
    ../modules/services/gnome-keyring.nix
    ../modules/services/polkit.nix
    ../modules/services/openssh.nix
    ../modules/services/sunshine.nix
    ../modules/services/pipewire.nix
    ../modules/services/guix.nix
    ../modules/security/sudo-rs.nix
    ../modules/security/wrappers.nix
    ../modules/virtualisation/libvirtd.nix
    ../modules/virtualisation/podman.nix
    ../modules/virtualisation/droidloom.nix
    ../modules/tools/file-map.nix
    ../modules/services/rime-gram-update.nix
#    ../modules/virtualisation/vmware-workstation.nix
  ];
}
