{
  inputs,
  pkgs,
  lib,
  ...
}: let
  # 与 noctalia 同源的 M3 调色：noctalia 源码（src/theme/m3_schemes.cpp）明确
  # 与 matugen 逐字节对齐（seed 提取 + 默认 TonalSpot scheme），这里沿用
  # matugen 在构建期从壁纸取色，再按 M3 dark role → tone 规范映射为 base16
  # 交给 stylix 下发。换壁纸 = 替换 configuration/wallpaper/wallpaper.png 后 rebuild。
  # noctalia 侧 role 名对照：primary/secondary/tertiary/error +
  # surface dim/container/low/high + outline(_variant) + on_*，见其 palette.mdx。
  matugenJson = pkgs.runCommand "matugen-colors.json" {} ''
    ${lib.getExe pkgs.matugen} -m dark -j hex --include-image-in-json false --source-color-index 0 image ${../wallpaper/wallpaper.png} > $out
  '';
  md3 = (builtins.fromJSON (builtins.readFile matugenJson)).palettes;
  # tone 读取带回退：matugen 只保证 5 步进键，M3 规范 tone（如 6/17）缺失时就近取值
  tone = palette: tones:
    let
      get = t:
        if builtins.hasAttr palette md3 && builtins.hasAttr t md3.${palette}
        then let v = md3.${palette}.${t};
             in if builtins.isString v then v else (v.color or v.hex or null)
        else null;
      pick = ts:
        if ts == [] then "#ff00ff"
        else let v = get (builtins.head ts); in if v == null then pick (builtins.tail ts) else v;
    in pick tones;

  # M3 dark role → base16（role 后注明规范 tone）
  base16Scheme = {
    base00 = tone "neutral" ["6" "5" "10"]; # surface_dim
    base01 = tone "neutral" ["10" "5"]; # surface_container_low
    base02 = tone "neutral" ["17" "15" "20"]; # surface_container_high（选区/高亮背景）
    base03 = tone "neutral_variant" ["30" "25" "40"]; # outline_variant（注释/弱化）
    base04 = tone "neutral_variant" ["60" "70" "50"]; # outline
    base05 = tone "neutral" ["90" "95"]; # on_surface（前景）
    base06 = tone "neutral" ["95" "90"];
    base07 = tone "neutral" ["100" "99" "98" "95"]; # 最亮前景
    base08 = tone "error" ["80" "70"]; # error（红）
    base09 = tone "tertiary" ["90" "80"]; # on_tertiary_container（橙位）
    base0A = tone "tertiary" ["80" "70"]; # tertiary（黄位）
    base0B = tone "secondary" ["90" "80"]; # on_secondary_container（绿位）
    base0C = tone "secondary" ["80" "70"]; # secondary（青位）
    base0D = tone "primary" ["80" "70"]; # primary（蓝）
    base0E = tone "primary" ["90" "80"]; # on_primary_container（品红位）
    base0F = tone "error" ["30" "25" "40"]; # error_container（深红/棕位）
  };
in {
  imports = [inputs.stylix.homeModules.stylix];

  # WSL 无 dbus/dconf 会话，禁用 dconf 写入（stylix 在无桌面的环境下必须）
  dconf.enable = false;

  stylix = {
    enable = true;
    autoEnable = true;
    image = ../wallpaper/wallpaper.png;
    polarity = "dark";
    base16Scheme = base16Scheme;

    fonts = {
      monospace = {
        name = lib.mkDefault "JetBrainsMono Nerd Font";
        package = lib.mkDefault pkgs.nerd-fonts.jetbrains-mono;
      };
      sansSerif = {
        name = lib.mkDefault "Noto Sans CJK SC";
        package = lib.mkDefault pkgs.noto-fonts-cjk-sans;
      };
      serif = {
        name = lib.mkDefault "Noto Serif CJK SC";
        package = lib.mkDefault pkgs.noto-fonts-cjk-sans;
      };
      emoji = {
        name = lib.mkDefault "Noto Color Emoji";
        package = lib.mkDefault pkgs.noto-fonts-color-emoji;
      };
    };

    # LazyVim 自己管理配色，交给它
    targets.neovim.enable = false;
  };
}
