# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/system/input-method.nix（fcitx5-rime 与 rimeDataPkgs）
#     - configuration/pkgs/data/rime-wanxiang-gram.nix（万象语法模型）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  # Rime 的用户配置目录。default.custom.yaml 由 Home Manager 声明式管理，
  # 这样切换系统后不需要再手动改 ~/.local/share/fcitx5/rime/。
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    # 覆盖之前手动创建的普通文件，之后完全由 Home Manager 管理。
    force = true;
    text = ''
      patch:
        # 万象拼音官方推荐的全局配置（schema_list/menu/switcher/ascii_composer/key_binder 等）
        __include: wanxiang_suggested_default:/
        # 保留原来的 F4 呼出方案菜单
        switcher/hotkeys:
          - Control+grave
          - Control+Shift+grave
          - F4
    '';
  };
}
