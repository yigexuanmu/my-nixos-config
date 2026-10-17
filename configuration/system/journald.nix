{ ... }: {
  services.journald.settings = {
    Journal = {
      SystemMaxUse = "1G";
      SystemMaxFileSize = "100M";
      RuntimeMaxUse = "256M";
    };
  };
}
