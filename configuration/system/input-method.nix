{
  pkgs,
  ...
}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      # 雾凇拼音（rime-ice）的数据必须通过 rimeDataPkgs 注入 fcitx5-rime 自己的
      # share/rime-data（librime 实际读取的数据目录）。
      # 若只把 rime-ice 单独列为 addon，它只会进 wrapper 的 share/ 目录，
      # librime 找不到 rime_ice 方案 → 输入时没有候选框。
      (fcitx5-rime.override {rimeDataPkgs = [rime-data rime-ice];})
      qt6Packages.fcitx5-chinese-addons
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-qt
      fcitx5-mellow-themes
    ];
  };
}
