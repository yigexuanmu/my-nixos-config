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
