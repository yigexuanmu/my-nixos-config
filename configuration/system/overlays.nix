# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - flake.nix（inputs 来源）
#     - configuration/pkgs/default.nix（overlays.default 定义）
#     - configuration/home/nixpkgs.nix（Home 侧 overlay）
# ────────────────────────────────────────────────────────────

{
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
    (final: prev: {
      inherit (prev.lixPackageSets.latest)
        nixpkgs-review
        nix-direnv
        nix-eval-jobs
        nix-fast-build
        colmena;
    })
  ];
}
