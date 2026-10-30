{
  inputs,
  pkgs,
  ...
}: {
  nix.package = pkgs.lixPackageSets.lix_2_96.lix;
  nixpkgs.config.allowUnfree = true;
  nix.settings.substituters = [
    "http://127.0.0.1:5000"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://nix-community.cachix.org"
    "https://attic.xuyh0120.win/lantian"
    "https://cache.nixos-cuda.org"
    "https://cache.flox.dev"
    "https://noctalia.cachix.org"
    "https://yigexuanmu.github.io/miyu-agent-nix/"
  ];
  nix.settings.trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "miyu-agent-nix-1:4hk2EYv/cb00ccSkWL9snAoB92l/15PGuiS8qlYMcBQ="
  ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  services.nix-serve = {
    enable = true;
    # 如果通过 localhost 访问且不关心签名，可以简化或跳过密钥配置
  };
  # 仅系统作用域: pnpm-9 由系统级依赖引入（与 Home 的 pnpm-10 版本不同，勿合并）
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];
  system.stateVersion = "26.05";
}
