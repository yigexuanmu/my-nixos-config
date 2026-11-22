# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/device/disko.nix（/gnu、/gnu/store 子卷）
#     - configuration/system/boot.nix（自动：同设 fileSystems.*.neededForBoot）
# ────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  lib,
  ...
}:{
  # Guix store 需在引导早期可用
  fileSystems."/gnu".neededForBoot = true;
  fileSystems."/gnu/store".neededForBoot = true;

  services.guix = {
    enable = true;
    package = pkgs.guix;
    nrBuildUsers = 20;
    gc = {
      enable = true;
      # 执行频率/时间，遵循 systemd.time(7) 格式
      # 例如 "weekly"、"daily" 或 "03:15"
      dates = "weekly";
      # 传递给 guix gc 的参数
      extraArgs = [
       "--delete-generations=1m"  # 删除超过 1 个月的旧生成
       "--free-space=10G"          # 确保至少有 10G 空闲空间
       "--optimize"                # 优化存储（去重）
      ];
    };
    substituters = {
      urls = [
       # 上海交大镜像（推荐，国内速度较快）
       "https://mirrors.sjtug.sjtu.edu.cn/guix"
       "https://mirrors.sjtug.sjtu.edu.cn/guix-bordeaux"
       # CERNET 镜像（备选）
       "https://mirrors.cernet.edu.cn/guix"
       # 官方源作为回退
       "https://ci.guix.gnu.org"
       "https://bordeaux.guix.gnu.org"
      ];
       # 无需修改 authorizedKeys，默认已包含官方签名密钥
    };
  };
}
