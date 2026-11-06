{
  ...
}: {
  xdg.configFile = {
    "kitty/kitty.conf".source = ./dotfiles/kitty.conf;
    # 由 noctalia 生成的主题，此处固化以脱离 shell 依赖
    "kitty/themes/noctalia.conf".source = ./dotfiles/themes/noctalia.conf;
  };
}
