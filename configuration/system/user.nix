{
  ...
}: {
  users.users.mioha = {
    isNormalUser = true;
    home = "/home/mioha";
    extraGroups = ["wheel" "networkmanager" "libvirtd" "kvm" "input" "uinput" "podman"];
  };
}
