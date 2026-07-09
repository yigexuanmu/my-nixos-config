{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    nwg-look
    wf-recorder
    slurp
    grim
    imv
    wl-clipboard
    pywalfox-native
    libnotify
    nautilus
    gvfs
    inputs.we-layerd.packages.x86_64-linux.default
  ];
}
