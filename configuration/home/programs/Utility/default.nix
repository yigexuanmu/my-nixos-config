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
