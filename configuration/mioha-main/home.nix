# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：flake.nix（homeConfigurations.mioha）
#   下游（本文件引用）：
#     - configuration/home/programs.nix
#     - configuration/home/nixpkgs.nix
#     - configuration/home/session.nix
#     - configuration/home/mango-session.nix
#     - configuration/home/file-map.nix
#   相关（语义关联）：configuration/mioha-main/system.nix（同一主机）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  imports = [
    ../home/programs.nix
    ../home/nixpkgs.nix
    ../home/session.nix
    ../home/mango-session.nix
    ../home/file-map.nix
  ];
}
