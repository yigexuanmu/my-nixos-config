# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/pkgs/tools/file-map/default.nix（自动：使用 file-map）
# ────────────────────────────────────────────────────────────

{
  pkgs,
  lib,
  ...
}: {
  # 每次 nixos-rebuild switch/boot 的 activation 阶段，重算 /etc/nixos 里
  # 各 .nix 文件的「文件关联」头部注释（上游/下游全自动，相关按证据自动补充）。
  #
  # 说明：
  #   * activation 以 root 运行；脚本只改写已存在的文件、不新建文件，
  #     所以文件属主不会变成 root，mioha 之后照常 git 操作。
  #   * 失败只告警不阻塞 switch（文档性注释不值得卡住一次 rebuild）。
  #   * 不想自动跑就删掉 modules.nix 里对 ../modules/tools/file-map.nix 的 import。
  environment.systemPackages = [pkgs.file-map];

  system.activationScripts.fileAssociations = {
    deps = [];
    text = ''
      if [ -d /etc/nixos ]; then
        echo "file-map: 重算文件关联头部注释…" >&2
        ${lib.getExe pkgs.file-map} --root /etc/nixos >&2 ||
          echo "file-map: 跳过（不阻塞 activation）" >&2
      fi
    '';
  };
}
