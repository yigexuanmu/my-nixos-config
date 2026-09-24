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
    "https://attic.xuyh0120.win/lantian"
  ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  # 仅系统作用域: pnpm-9 由系统级依赖引入（与 Home 的 pnpm-10 版本不同，勿合并）
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];
  system.stateVersion = "26.05";
}
