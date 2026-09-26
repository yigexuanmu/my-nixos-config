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
  xdg.configFile."xfce4/helpers.rc" = {
    force = true;
    text = ''
      # Managed by Home Manager
      TerminalEmulator=kitty
      TextEditor=kitty -e nvim
    '';
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = ["thunar.desktop"];
      "inode/mount-point" = ["thunar.desktop"];
      "text/html" = ["google-chrome.desktop"];
      "x-scheme-handler/http" = ["google-chrome.desktop"];
      "x-scheme-handler/https" = ["google-chrome.desktop"];
      "x-scheme-handler/about" = ["google-chrome.desktop"];
      "x-scheme-handler/unknown" = ["google-chrome.desktop"];
    };
  };
  xdg.configFile."mimeapps.list".force = true;
  home.sessionVariables = {
    EDITOR = "kitty -e nvim";
    TERMINAL = "kitty";
    BROWSER = "google-chrome";
  };
}
