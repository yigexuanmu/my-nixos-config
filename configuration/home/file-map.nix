# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/home.nix
#   下游（本文件引用）：configuration/pkgs/tools/file-map/default.nix
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{
  pkgs,
  lib,
  ...
}: let
  # 与 NixOS 侧同一个生成器：nixos-file-map
  file-map = pkgs.callPackage ../pkgs/tools/file-map { };
in {
  # Home Manager 的 activation 与 NixOS 的 system.activationScripts 是两套东西：
  # `nh os switch` 只跑 NixOS 那套，`nh home switch` 只跑这套。
  # 所以两边各挂一次，任何一条命令都能把头部注释刷新。
  #
  # 以 mioha 身份运行（HM activation 本来就是普通用户），/etc/nixos 属主就是 mioha，
  # 不需要提权；失败只告警，不阻塞 home-manager switch。
  home.activation.fileAssociations = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -z "''${DRY_RUN:-}" ] && [ -d /etc/nixos ]; then
      ${file-map}/bin/nixos-file-map --root /etc/nixos >&2 ||
        echo "file-map: 跳过（不阻塞 activation）" >&2
    fi
  '';
}
