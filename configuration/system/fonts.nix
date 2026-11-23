# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/system.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/pkgs/data/fonts/harmonyos-sans.nix（harmonyos-sans 由 overlay 提供）
# ────────────────────────────────────────────────────────────

{ pkgs, ... }: {
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.fira-code
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      wqy_microhei
      harmonyos-sans
    ];
    fontconfig = {
      defaultFonts = {
        sansSerif = ["HarmonyOS Sans SC" "Noto Sans CJK SC"];
        serif = ["Noto Serif CJK SC"];
        monospace = ["JetBrainsMono Nerd Font" "Noto Sans Mono CJK SC"];
      };
    };
  };
}
