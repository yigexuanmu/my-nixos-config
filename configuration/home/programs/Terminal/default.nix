# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/home/programs/Terminal/fastfetch/default.nix
#     - configuration/home/programs/Terminal/fish/default.nix
#     - configuration/home/programs/Terminal/kitty/default.nix
#     - configuration/home/session.nix（TERMINAL/EDITOR）
# ────────────────────────────────────────────────────────────

{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    yazi
    kitty
    (pkgs.symlinkJoin {
      name = "btop-wrapped";
      paths = [ pkgs.btop ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/btop \
          --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
      '';
    })
    fastfetch
    starship
    eza
    fzf
    tty-clock
    chafa
    fish
    zellij
  ];
}
