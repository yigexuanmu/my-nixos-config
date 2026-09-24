{ pkgs, lib, ... }:

{
  environment.systemPackages = [ pkgs.clash-party ];

  security.wrappers.mihomo-party = {
    owner = "root";
    group = "root";
    capabilities = "cap_net_bind_service,cap_net_raw,cap_net_admin=+ep";
    source = "${pkgs.clash-party}/bin/mihomo-party";
  };
}
