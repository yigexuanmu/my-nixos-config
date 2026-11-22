# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/pkgs/data/rime-wanxiang-gram.nix（万象语法模型 rimeDataPkgs）
#     - configuration/home/programs/Desktop/rime.nix（Rime 用户配置）
# ────────────────────────────────────────────────────────────

{
  pkgs,
  ...
}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      # 万象拼音的数据和语法模型都通过 rimeDataPkgs 注入 fcitx5-rime 自己的
      # share/rime-data（librime 实际读取的数据目录）。
      # rime-wanxiang-gram 是本地打包的 wanxiang-lts-zh-hans.gram，
      # 不再需要手动往 ~/.local/share/fcitx5/rime/ 里放。
      (fcitx5-rime.override {
        rimeDataPkgs = [rime-data rime-wanxiang rime-wanxiang-gram];
      })
      qt6Packages.fcitx5-chinese-addons
      fcitx5-gtk
      qt6Packages.fcitx5-qt
      fcitx5-mellow-themes
    ];
  };
}
