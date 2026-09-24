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
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/mihomo-party-org/clash-party/releases/download/v${version}/clash-party-linux-${version}-amd64.deb";
    sha256 = "5355b359bdbdfc0cac9e53f114c953a143a85f72a9af74caa3ffbe885f485e4a";
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
