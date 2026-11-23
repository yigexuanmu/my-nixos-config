# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/home/programs.nix
#   下游（本文件引用）：无
#   相关（语义关联）：无
# ────────────────────────────────────────────────────────────

{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    tesseract
    gimp
    kdePackages.kdenlive
    evtest
    showmethekey
    scrcpy
    zip
    xz
    unzip
    (pkgs.symlinkJoin {
      name = "7zip";
      paths = [ pkgs._7zz ];
      postBuild = ''
        for alias in 7z 7za 7zr; do
          ln -s $out/bin/7zz $out/bin/$alias
        done
      '';
    })
    file-roller
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    mtr
    iperf3
    dnsutils
    ldns
    aria2
    socat
    dmg2img
    nmap
    ipcalc
    iotop
    iftop
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    wget
    imagemagick
    snapper
    bluetui
    bluetuith
    impala
  ];
}
