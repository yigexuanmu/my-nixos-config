{
  lib,
  stdenv,
  python3,
  xcursorgen,
  hyprcursor,
  unzip,
}:

stdenv.mkDerivation {
  pname = "windows-cursor-theme";
  version = "1.0";

  src = ./source.zip;

  nativeBuildInputs = [
    unzip
    xcursorgen
    hyprcursor
    (python3.withPackages (ps: [ps.pillow]))
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    unzip -q "$src" -d source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    themeSrc="$TMPDIR/src/Windows-Cursor"
    mkdir -p "$themeSrc"
    PYTHONPATH=${./tool} python -m win2xcursor \
      --src source \
      --out "$themeSrc" \
      --name Windows-Cursor \
      --formats xcursor,hyprcursor \
      --sizes 24,30,32,36,42,48,60,64,72,96

    mkdir -p "$out/share/icons/Windows-Cursor"
    cp -r "$themeSrc/cursors" "$themeSrc/index.theme" "$out/share/icons/Windows-Cursor/"

    mkdir -p "$TMPDIR/compiled"
    hyprcursor-util -c "$themeSrc" -o "$TMPDIR/compiled"
    cp "$TMPDIR/compiled/theme_Windows-Cursor/manifest.hl" "$out/share/icons/Windows-Cursor/"
    cp -r "$TMPDIR/compiled/theme_Windows-Cursor/hyprcursors" "$out/share/icons/Windows-Cursor/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Windows cursor scheme converted to an animated Xcursor theme";
    platforms = platforms.linux;
  };
}
