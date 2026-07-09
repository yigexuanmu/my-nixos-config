{
  config,
  ...
}: {
  targets.genericLinux.enable = true;
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
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };
}
