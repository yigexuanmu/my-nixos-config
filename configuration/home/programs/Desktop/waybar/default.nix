{
  ...
}: {
  xdg.configFile = {
    "waybar/config.jsonc".source = ./dotfiles/config.jsonc;
    "waybar/modules.jsonc".source = ./dotfiles/modules.jsonc;
    "waybar/modules-dividers.jsonc".source = ./dotfiles/modules-dividers.jsonc;
    "waybar/style.css".source = ./dotfiles/style.css;
    "waybar/scripts/cava.sh".source = ./dotfiles/scripts/cava.sh;
    "waybar/scripts/check-updates.sh".source = ./dotfiles/scripts/check-updates.sh;
    "waybar/scripts/command-center.sh".source = ./dotfiles/scripts/command-center.sh;
    "waybar/scripts/old-longshot.sh".source = ./dotfiles/scripts/old-longshot.sh;
    "waybar/scripts/play-sound.sh".source = ./dotfiles/scripts/play-sound.sh;
    "waybar/scripts/power-screenshot.sh".source = ./dotfiles/scripts/power-screenshot.sh;
    "waybar/scripts/reload-waybar.sh".source = ./dotfiles/scripts/reload-waybar.sh;
    "waybar/scripts/screenrec".source = ./dotfiles/scripts/screenrec;
    "waybar/scripts/screenshot.sh".source = ./dotfiles/scripts/screenshot.sh;
    "waybar/scripts/select-network-tui.sh".source = ./dotfiles/scripts/select-network-tui.sh;
    "waybar/scripts/toggle-bluetooth.sh".source = ./dotfiles/scripts/toggle-bluetooth.sh;
    "noctalia/templates.toml".source = ./dotfiles/noctalia/templates.toml;
    "noctalia/templates/waybar-colors.css".source = ./dotfiles/noctalia/templates/waybar-colors.css;
  };
}
