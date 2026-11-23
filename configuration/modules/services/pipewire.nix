# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/home/programs/Entertain/cava/default.nix（cava 音频可视化）
#     - configuration/home/programs/Desktop/waybar/default.nix（cava 脚本）
#     - configuration/modules/programs/steam.nix（32 位 Wine/Steam 音频）
# ────────────────────────────────────────────────────────────

{
  ...
}: {
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # 跑 32 位 Wine/Steam 游戏
    jack.enable = true; # JACK 应用兼容

    # 允许音频图在这些采样率之间切换，避免 44.1k 等音源被固定重采样到 48k。
    extraConfig.pipewire."10-clock.conf" = {
      "context.properties" = {
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 352800 384000 ];
      };
    };
  };
}
