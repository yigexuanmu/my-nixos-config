# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：flake.nix（overlays.default）
#   下游（本文件引用）：
#     - configuration/pkgs/data/fonts/harmonyos-sans.nix
#     - configuration/pkgs/data/cursors/windows-cursor.nix
#     - configuration/pkgs/data/rime-wanxiang-gram/rime-wanxiang-gram.nix
#     - configuration/pkgs/tools/codearts-agent/default.nix
#     - configuration/pkgs/tools/networking/clash-party.nix
#     - configuration/pkgs/tools/file-map/default.nix
#   相关（语义关联）：configuration/system/overlays.nix（overlay 在系统侧生效）
# ────────────────────────────────────────────────────────────

{ pkgs, ... }:
{
  harmonyos-sans = pkgs.callPackage ./data/fonts/harmonyos-sans.nix { };
  windows-cursor-theme = pkgs.callPackage ./data/cursors/windows-cursor.nix { };
  rime-wanxiang-gram = pkgs.callPackage ./data/rime-wanxiang-gram/rime-wanxiang-gram.nix { };
  clash-party = pkgs.callPackage ./tools/networking/clash-party.nix { };
  codearts-agent = pkgs.callPackage ./tools/codearts-agent { };
  file-map = pkgs.callPackage ./tools/file-map { };
}
