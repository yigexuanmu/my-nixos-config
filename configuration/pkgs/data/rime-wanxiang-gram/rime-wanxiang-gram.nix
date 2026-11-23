# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/pkgs/default.nix（callPackage）
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/system/input-method.nix（rimeDataPkgs）
#     - configuration/home/programs/Desktop/rime.nix（Rime 用户配置）
# ────────────────────────────────────────────────────────────

{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "rime-wanxiang-gram";
  version = "unstable-2026-11-18";

  # 注意：上游 LTS 是滚动 tag，gram 更新后这里的 sha256 也要同步更新。
  src = fetchurl {
    url = "https://github.com/amzxyz/rime-wanxiang-data/releases/download/LTS/wanxiang-lts-zh-hans.gram";
    sha256 = "e9ddd501b7d536bc5ea1346f8f900ae49a719a05be349e0a17cb27e717143ca5";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  # 滚动发布没有固定版本号，hash 靠 ./rime-wanxiang-gram-update.py 自动改
  # （systemd timer rime-gram-update 每天跑一次，见 configuration/modules/services/）
  passthru.updateScript = ./rime-wanxiang-gram-update.py;

  installPhase = ''
    runHook preInstall
    install -Dm644 "$src" "$out/share/rime-data/wanxiang-lts-zh-hans.gram"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Wanxiang LTS Chinese grammar model for Rime";
    homepage = "https://github.com/amzxyz/rime-wanxiang-data";
    license = licenses.cc-by-40;
    platforms = platforms.all;
  };
}
