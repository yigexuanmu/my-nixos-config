# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：
#     - configuration/pkgs/default.nix
#     - configuration/home/file-map.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/pkgs/tools/codearts-agent/default.nix（自动：共享 doInstallCheck、installCheckPhase）
# ────────────────────────────────────────────────────────────

{
  lib,
  stdenv,
  makeWrapper,
  python3,
}:
stdenv.mkDerivation {
  pname = "nixos-file-map";
  version = "2";

  src = ./.;

  nativeBuildInputs = [makeWrapper];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # 构建期语法检查：Python 写错在构建阶段就失败，而不是等 activation 才发现
    ${python3}/bin/python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' file-map.py


    install -Dm644 file-map.py $out/share/nixos-file-map/file-map.py
    makeWrapper ${python3}/bin/python3 $out/bin/nixos-file-map \
      --add-flags $out/share/nixos-file-map/file-map.py

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/nixos-file-map --help > /dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "自动维护 /etc/nixos 各 .nix 文件的「文件关联」头部注释";
    mainProgram = "nixos-file-map";
    platforms = lib.platforms.linux;
  };
}
