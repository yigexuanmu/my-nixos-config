# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{
  pkgs,
  ...
}: let
  # 被跟踪的 nix 文件：里面的 version/sha256 由脚本改写
  gramFile = "/etc/nixos/configuration/pkgs/data/rime-wanxiang-gram/rime-wanxiang-gram.nix";
in {
  # 万象 LTS 是"固定 tag、覆盖式替换资产"的滚动发布，Nix 必须钉死 sha256，
  # 所以在 Nix 求值里没有任何办法自动跟随。这里的做法是退一步：
  # 每次 nixos-rebuild 的 activation 阶段查一次 GitHub API 拿资产 digest
  # （只几百字节，不下载 390MB），变了就把 .nix 里的 version 日期与 sha256 改写掉。
  # 注意时序：activation 在构建之后，所以改完是"下次 rebuild 生效"。
  #
  # 关掉它：删掉 modules.nix 里对 ../modules/services/rime-gram-update.nix 的 import。
  # 手动单跑：python3 configuration/pkgs/data/rime-wanxiang-gram/rime-wanxiang-gram-update.py --check|--apply
  system.activationScripts.rimeGramUpdate = {
    deps = [];
    text = ''
      if [ -d /etc/nixos ]; then
        echo "rime-gram: 检查万象 LTS 语法模型是否有更新…" >&2
        ${pkgs.python3}/bin/python3 ${
          ../../pkgs/data/rime-wanxiang-gram/rime-wanxiang-gram-update.py
        } --file ${gramFile} --apply >&2 ||
          echo "rime-gram: 跳过（不阻塞 activation）" >&2
      fi
    '';
  };
}
