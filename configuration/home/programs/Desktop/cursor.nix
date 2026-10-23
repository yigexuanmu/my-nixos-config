{
  lib,
  pkgs,
  ...
}: let
  cursorName = "Windows-Cursor";
  cursorSize = 48;
in {
  home.pointerCursor = {
    enable = true;
    package = pkgs.callPackage ../../../pkgs/data/cursors/windows-cursor.nix { };
    name = cursorName;
    size = cursorSize;
    gtk.enable = true;
    x11.enable = true;
  };

  # Also put the cursor variables into the systemd user environment, so
  # services and apps started outside niri (and Xwayland on next login)
  # see the same theme and size.
  systemd.user.sessionVariables = {
    XCURSOR_THEME = cursorName;
    XCURSOR_SIZE = toString cursorSize;
    HYPRCURSOR_THEME = cursorName;
    HYPRCURSOR_SIZE = toString cursorSize;
  };

  # GTK reads the cursor from settings.ini; nwg-look owns the rest of those
  # files, so only the two cursor keys are rewritten.
  home.activation.windowsCursor = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for gtkDir in gtk-3.0 gtk-4.0; do
      ini="$HOME/.config/$gtkDir/settings.ini"
      mkdir -p "$(dirname "$ini")"
      touch "$ini"
      ${pkgs.gnused}/bin/sed -i \
        -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=${cursorName}|" \
        -e "s|^gtk-cursor-theme-size=.*|gtk-cursor-theme-size=${toString cursorSize}|" \
        "$ini"
      ${pkgs.gnugrep}/bin/grep -q '^gtk-cursor-theme-name=' "$ini" \
        || echo "gtk-cursor-theme-name=${cursorName}" >> "$ini"
      ${pkgs.gnugrep}/bin/grep -q '^gtk-cursor-theme-size=' "$ini" \
        || echo "gtk-cursor-theme-size=${toString cursorSize}" >> "$ini"
    done

    if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/cursor-theme "'${cursorName}'" || true
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/cursor-size "${toString cursorSize}" || true
    fi
  '';
}
