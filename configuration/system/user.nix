{
  ...
}: {
  users.users.mioha = {
    isNormalUser = true;
    home = "/home/mioha";
    extraGroups = ["wheel" "networkmanager" "libvirtd" "kvm" "input" "audio" "uinput" "podman"];
  };
}
