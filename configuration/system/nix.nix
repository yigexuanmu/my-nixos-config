{
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];
  system.stateVersion = "26.05";
}
