{
  pkgs,
  ...
}: {
  # fish 作为登录 shell 必须系统级启用，否则 PATH 缺少 nix 目录
  programs.fish.enable = true;

  users.users.mioha = {
    isNormalUser = true;
    home = "/home/mioha";
    extraGroups = ["wheel" "podman"];
    shell = pkgs.fish;
  };
}
