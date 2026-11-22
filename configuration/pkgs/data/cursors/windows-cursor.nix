# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：
#     - configuration/pkgs/default.nix（callPackage）
#     - configuration/home/programs/Desktop/cursor.nix（直接 callPackage）
#   下游（本文件引用）：无
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{
  lib,
  stdenv,
  python3,
  xcursorgen,
  unzip,
}:

stdenv.mkDerivation {
  pname = "windows-cursor-theme";
  version = "1.0";

  src = ./source.zip;

  nativeBuildInputs = [
    unzip
    xcursorgen
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
    mkdir -p "$out/share/icons"
    python -m venv --without-pip --system-site-packages "$TMPDIR/venv"
    PYTHONPATH=${./tool} "$TMPDIR/venv/bin/python" -m win2xcursor \
      --src source \
      --out "$out/share/icons/Windows-Cursor" \
      --name Windows-Cursor \
      --sizes 24,30,32,36,42,48,60,64,72,96
    runHook postInstall
  '';

  meta = with lib; {
    description = "Windows cursor scheme converted to an animated Xcursor theme";
    platforms = platforms.linux;
  };
}
