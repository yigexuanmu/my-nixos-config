{...}: {
  systemd.tmpfiles.rules = [
    "d /var/tmp 1777 root root -"
    "d /var/build 0755 root root -"
  ];
}
