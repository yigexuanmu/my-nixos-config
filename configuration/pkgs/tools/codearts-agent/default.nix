# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：
#     - configuration/pkgs/default.nix
#     - configuration/home/programs/Develop/default.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/pkgs/tools/networking/clash-party.nix（自动：共享 alsa-lib、at-spi2-atk）
#     - configuration/modules/programs/nix-ld.nix（自动：共享 alsa-lib、dbus）
#     - configuration/pkgs/tools/file-map/default.nix（自动：共享 doInstallCheck、installCheckPhase）
# ────────────────────────────────────────────────────────────

# 华为 CodeArts Agent（基于 VS Code / Electron）的 deb 打包。
# deb 构建时从华为 CDN 拉取；它把程序装在 /usr/share/codearts-agent，
# 这里改为 store 路径并修正 wrapper。

{ lib
, stdenv
, dpkg
, autoPatchelfHook
, fetchurl
, alsa-lib
, atk
, at-spi2-atk
, at-spi2-core
, cairo
, curl
, dbus
, expat
, glib
, gtk3
, libdrm
, libglvnd
, libx11
, libxcb
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxkbcommon
, libxkbfile
, libxrandr
, libxshmfence
, libXScrnSaver
, libXtst
, mesa
, nspr
, nss
, pango
, systemd
, vulkan-loader
, xdg-utils
, cacert
}:

stdenv.mkDerivation rec {
  pname = "codearts-agent";
  version = "26.11.200";

  src = fetchurl {
    url = "https://codearts-agent-obs-cdn.huaweicloud.com/codearts/ai/latest/codearts-agent-linux-x64-26.11.200-a26dc34.deb";
    hash = "sha256-PRQlaT6KBFefN50veaN0iaSgv+LKd85KexJrDkQpKEs=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook ];

  # 附带的 musl 版 koffi.node 用不到（glibc 系统会选 linux_x64 那份）
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  # Electron 动态库依赖（对应 deb 的 Depends）
  buildInputs = [
    alsa-lib atk at-spi2-atk at-spi2-core cairo curl dbus expat glib gtk3
    libdrm libglvnd libx11 libxcb libxcomposite libxdamage libxext libxfixes
    libxkbcommon libxkbfile libxrandr libxshmfence libXScrnSaver libXtst
    mesa nspr nss pango systemd vulkan-loader
  ];

  # wrapper 会调用 xdg-open，CA 证书用于 HTTPS
  propagatedBuildInputs = [ xdg-utils cacert ];

  # 直接 dpkg -x 会尝试给 chrome-sandbox 设 setuid，Nix 沙箱不允许；
  # 经 tar 流解包并去掉特权位（后面 installPhase 会删掉该文件）。
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile $src | tar --no-same-owner --no-same-permissions -xf -
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp -r usr/share/codearts-agent $out/share/codearts-agent
    for d in applications pixmaps bash-completion appdata; do
      if [ -d usr/share/$d ]; then
        cp -r usr/share/$d $out/share/$d
      fi
    done

    # nix store 不允许 setuid；Electron 会退回 user namespace sandbox
    rm -f $out/share/codearts-agent/chrome-sandbox

    # 上游 wrapper 靠 readlink -f "$0" 定位安装目录，必须用符号链接而非包装脚本
    ln -s $out/share/codearts-agent/bin/codearts-agent $out/bin/codearts-agent

    # desktop 里的 /usr/share/... 指向 store；先替换长路径再替换短路径
    for f in $out/share/applications/*.desktop; do
      substituteInPlace "$f" \
        --replace "/usr/share/codearts-agent/codearts-agent" "$out/bin/codearts-agent" \
        --replace "/usr/share/codearts-agent" "$out/share/codearts-agent"
    done

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test -x $out/bin/codearts-agent
    test -x $out/share/codearts-agent/codearts-agent
    ! grep -q '/usr/share/codearts-agent' $out/share/applications/codearts-agent.desktop
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "CodeArts Agent - Huawei's VS Code based IDE";
    homepage = "https://www.huaweicloud.com/product/codearts/ai.html";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codearts-agent";
  };
}
