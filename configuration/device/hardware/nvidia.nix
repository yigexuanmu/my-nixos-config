# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/device.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/system/boot.nix（由 config.boot.kernelPackages 提供 nvidiaPackages）
#     - configuration/modules/virtualisation/droidloom.nix（使用该 GPU）
# ────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  ...
}: {
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.new_feature;
  };
  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
  ];
}
