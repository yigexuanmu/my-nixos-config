{
  inputs,
  pkgs,
  ...
}: {
  nix.package = pkgs.lixPackageSets.latest.lix;
  nixpkgs.config.allowUnfree = true;
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://nix-community.cachix.org"
    "https://attic.xuyh0120.win/lantian"
    "https://cache.xinux.uz"
  ];
  nix.settings.trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  # 仅系统作用域: pnpm-9 由系统级依赖引入（与 Home 的 pnpm-10 版本不同，勿合并）
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];
  system.stateVersion = "26.05";
}
