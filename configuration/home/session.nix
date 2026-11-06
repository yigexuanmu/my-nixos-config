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
