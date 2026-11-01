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

  # osu-lazer-bin 不带 MIME 定义，freedesktop.org.xml 里也没有 x-osu 类型。
  # 关键点：.osz 本质是 zip，不给后缀注册 glob 的话它会被认成 application/zip，
  # 下面绑的 osu! 就完全不会生效（实测：无定义 = application/zip）。
  # 所以这里只保留后缀 glob，不碰 .osu（它是文本格式，留给 text/plain 更省事）。
  xdg.dataFile."mime/packages/osu.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-osu-beatmap-archive">
        <comment>osu! beatmap archive</comment>
        <glob pattern="*.osz"/>
      </mime-type>
      <mime-type type="application/x-osu-skin-archive">
        <comment>osu! skin archive</comment>
        <glob pattern="*.osk"/>
      </mime-type>
      <mime-type type="application/x-osu-replay">
        <comment>osu! replay</comment>
        <glob pattern="*.osr"/>
      </mime-type>
      <mime-type type="application/x-osu-storyboard">
        <comment>osu! storyboard</comment>
        <glob pattern="*.osb"/>
      </mime-type>
    </mime-info>
  '';

  # 需要它才会在 activation 时跑 update-mime-database，上面的 xml 才进 ~/.local/share/mime
  xdg.mime.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # ---- 目录与浏览器 ----
      "inode/directory" = ["thunar.desktop"];
      "inode/mount-point" = ["thunar.desktop"];
      "text/html" = ["google-chrome.desktop"];
      "x-scheme-handler/http" = ["google-chrome.desktop"];
      "x-scheme-handler/https" = ["google-chrome.desktop"];
      "x-scheme-handler/about" = ["google-chrome.desktop"];
      "x-scheme-handler/unknown" = ["google-chrome.desktop"];

      # ---- 图片 → imv（想用 GIMP 编辑 svg 就把 svg 那行改成 gimp.desktop）----
      "image/png" = ["imv.desktop"];
      "image/jpeg" = ["imv.desktop"];
      "image/gif" = ["imv.desktop"];
      "image/webp" = ["imv.desktop"];
      "image/bmp" = ["imv.desktop"];
      "image/tiff" = ["imv.desktop"];
      "image/avif" = ["imv.desktop"];
      "image/heif" = ["imv.desktop"];
      "image/jxl" = ["imv.desktop"];
      "image/qoi" = ["imv.desktop"];
      "image/x-farbfeld" = ["imv.desktop"];
      "image/svg+xml" = ["imv.desktop"];

      # ---- osu!（配合上面的 mime glob 定义）----
      "application/x-osu-beatmap-archive" = ["osu!.desktop"];
      "application/x-osu-skin-archive" = ["osu!.desktop"];
      "application/x-osu-replay" = ["osu!.desktop"];
      "application/x-osu-storyboard" = ["osu!.desktop"];
      "x-scheme-handler/osu" = ["osu!.desktop"];
    };
  };
  xdg.configFile."mimeapps.list".force = true;
  home.sessionVariables = {
    EDITOR = "kitty -e nvim";
    TERMINAL = "kitty";
    BROWSER = "google-chrome";
  };
}
