# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/home.nix
#   下游（本文件引用）：
#     - configuration/home/programs/Desktop/default.nix
#     - configuration/home/programs/Desktop/fuzzel/default.nix
#     - configuration/home/programs/Desktop/niri/default.nix
#     - configuration/home/programs/Desktop/rime.nix
#     - configuration/home/programs/Desktop/waybar/default.nix
#     - configuration/home/programs/Develop/default.nix
#     - configuration/home/programs/Entertain/default.nix
#     - configuration/home/programs/Entertain/cava/default.nix
#     - configuration/home/programs/Games/default.nix
#     - configuration/home/programs/Terminal/default.nix
#     - configuration/home/programs/Terminal/fastfetch/default.nix
#     - configuration/home/programs/Terminal/fish/default.nix
#     - configuration/home/programs/Terminal/kitty/default.nix
#     - configuration/home/programs/Utility/default.nix
#   相关（语义关联）：
#     - configuration/home/session.nix
#     - configuration/system/user.nix（自动：同用 /home/mioha）
# ────────────────────────────────────────────────────────────

{
  inputs,
  pkgs,
  ...
}: {
  home.username = "mioha";
  home.homeDirectory = "/home/mioha";

  imports = [
    inputs.lazyvim.homeManagerModules.default
    ./programs/Desktop/default.nix
    ./programs/Desktop/fuzzel
    ./programs/Desktop/niri
    ./programs/Desktop/rime.nix
    ./programs/Desktop/waybar
    ./programs/Develop/default.nix
    ./programs/Entertain/default.nix
    ./programs/Entertain/cava
    ./programs/Games/default.nix
    ./programs/Terminal/default.nix
    ./programs/Terminal/fastfetch
    ./programs/Terminal/fish
    ./programs/Terminal/kitty
    ./programs/Utility/default.nix
  ];

  programs.lazyvim.enable = true;

  programs.git.enable = true;

  programs.home-manager.enable = true;

  services.mpris-proxy.enable = true;

  home.stateVersion = "26.05";
}
