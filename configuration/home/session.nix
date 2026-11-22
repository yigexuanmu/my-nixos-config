# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/home.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/home/programs/Terminal/default.nix（kitty/fish 包）
#     - configuration/home/programs/Terminal/kitty/default.nix（EDITOR/TERMINAL 指向 kitty）
#     - configuration/modules/services/flatpak.nix（flatpak 的 XDG_DATA_DIRS）
#     - configuration/device/disko.nix（自动：共享 /var/lib）
# ────────────────────────────────────────────────────────────

{
  config,
  ...
}: {
  xdg.systemDirs.data = [
    "/var/lib/flatpak/exports/share"
    "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
  ];
  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = ["kitty.desktop"];
    };
  };
  home.sessionVariables = {
    EDITOR = "kitty -e nvim";
    TERMINAL = "kitty";
    BROWSER = "google-chrome";
  };
}
