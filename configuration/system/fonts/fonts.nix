{
  pkgs,
  ...
}: let
  harmonyos-sans = pkgs.callPackage ./harmonyos-sans.nix {};
in {
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
