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
    inputs.miyu.packages.x86_64-linux.default
    fish
  ];
}
