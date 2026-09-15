{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # 原 catppuccin_mocha powerline 预设（starship-preset.toml）保留形状，
  # 其命名色映射到 stylix 的 M3 base16 色板（颜色随壁纸，色板见 ../theme.nix）
  c = config.lib.stylix.colors;
  catppuccinToMd3 = {
    rosewater = c.base07;
    flamingo = c.base06;
    pink = c.base0E;
    mauve = c.base0E;
    red = c.base08;
    maroon = c.base08;
    peach = c.base09;
    yellow = c.base0A;
    green = c.base0B;
    teal = c.base0C;
    sky = c.base0C;
    sapphire = c.base0D;
    blue = c.base0D;
    lavender = c.base0D;
    text = c.base05;
    subtext1 = c.base04;
    subtext0 = c.base04;
    overlay2 = c.base03;
    overlay1 = c.base03;
    overlay0 = c.base03;
    surface2 = c.base02;
    surface1 = c.base02;
    surface0 = c.base01;
    base = c.base01;
    mantle = c.base00;
    crust = c.base00;
  };
in {
  # fish/starship/btop/fzf/yazi 改由 programs.* 管理：stylix 的配色 target
  # 只作用于通过 home-manager programs 模块启用的程序
  programs.fish.enable = true;
  programs.btop.enable = true;
  programs.fzf.enable = true;
  programs.yazi.enable = true;

  programs.starship = {
    enable = true;
    settings = lib.mkMerge [
      (builtins.fromTOML (builtins.readFile ./starship-preset.toml))
      {
        palette = lib.mkForce "base16";
        palettes.base16 = builtins.mapAttrs (_: v: "#${v}") catppuccinToMd3;
      }
    ];
  };

  home.packages = with pkgs; [
    fastfetch
    eza
    tty-clock
    chafa
    cowsay
    inputs.miyu.packages.x86_64-linux.default
  ];
}
