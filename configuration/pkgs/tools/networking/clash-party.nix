# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/pkgs/default.nix（callPackage）
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/modules/packages/clash-party.nix
#     - configuration/modules/security/wrappers.nix
# ────────────────────────────────────────────────────────────

{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, alsa-lib
, at-spi2-atk
, at-spi2-core
, cairo
, cups
, dbus
, expat
, glib
, gtk3
, libdrm
, libglvnd
, libxkbcommon
, mesa
, nspr
, nss
, pango
, systemd
, makeWrapper
, libx11
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxrandr
, libxcb
}:

stdenv.mkDerivation rec {
  pname = "clash-party";
  version = "2.0.5";

  src = fetchurl {
    url = "https://github.com/mihomo-party-org/clash-party/releases/download/v${version}/clash-party-linux-${version}-amd64.deb";
    sha256 = "277a9cd9d41c946dc1a1b52231a6b32d88fd874d041371518f7da02874b4cdc6";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib at-spi2-atk at-spi2-core cairo cups dbus expat glib gtk3
    libdrm libglvnd libxkbcommon mesa nspr nss pango systemd
    libx11 libxcomposite libxdamage libxext libxfixes libxrandr libxcb
  ];

  unpackPhase = "dpkg -x $src .";

  installPhase = ''
    mkdir -p $out/bin $out/opt
    cp -r opt/clash-party $out/opt/
    cp -r usr/share $out/share

    # 链接启动文件
    ln -s $out/opt/clash-party/mihomo-party $out/bin/mihomo-party

    # 修正桌面图标路径
    substituteInPlace $out/share/applications/mihomo-party.desktop \
      --replace "/opt/clash-party/mihomo-party" "mihomo-party" || true
  '';

  meta = with lib; {
    mainProgram = "mihomo-party";
    description = "Another graphical clash-core and mihomo-core client";
    homepage = "https://github.com/mihomo-party-org/mihomo-party";
    license = licenses.gpl3;
    platforms = [ "x86_64-linux" ];
  };
}
