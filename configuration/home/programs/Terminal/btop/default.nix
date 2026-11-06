{
  ...
}: {
  # btop.conf 里的 color_theme = "noctalia" 指向这里
  xdg.configFile = {
    "btop/themes/noctalia.theme".source = ./dotfiles/themes/noctalia.theme;
  };
}
