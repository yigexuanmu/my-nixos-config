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
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = ["org.gnome.Nautilus.desktop"];
      "inode/mount-point" = ["org.gnome.Nautilus.desktop"];
    };
  };
  xdg.configFile."mimeapps.list".force = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };
}
