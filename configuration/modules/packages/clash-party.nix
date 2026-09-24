{ pkgs, lib, ... }:

{
  environment.systemPackages = [ pkgs.clash-party ];
}
