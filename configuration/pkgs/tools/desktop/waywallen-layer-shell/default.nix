{
  lib,
  stdenv,
  fetchurl,
  wayland,
  vulkan-loader,
  glibc,
  patchelf,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "waywallen-layer-shell";
  version = "0.4.2";

  src = fetchurl {
    url = "https://github.com/waywallen/waywallen-display/releases/download/v${version}/waywallen-layer-shell-${version}-x86_64.tar.gz";
    sha256 = "a2c4fe03547fddb74bf76a6ef7c7a8616cc72f525b286ee9489760cc77fd1748";
  };

  nativeBuildInputs = [patchelf makeWrapper];
  buildInputs = [wayland vulkan-loader glibc stdenv.cc.cc.lib];

  unpackPhase = "tar -xzf $src";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp waywallen-layer-shell-${version}-x86_64/waywallen-layer-shell $out/bin/
    cp -r waywallen-layer-shell-${version}-x86_64/share/. $out/share/

    # 用老式 DT_RPATH（优先于 LD_LIBRARY_PATH），避免 nix-ld 路径里的
    # 32 位 libwayland-client.so.0 抢先命中；同时固定为 Nix glibc 解释器。
    patchelf --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 \
      --force-rpath \
      --set-rpath "${wayland}/lib:${glibc}/lib:${stdenv.cc.cc.lib}/lib" \
      $out/bin/waywallen-layer-shell

    # libvulkan.so.1 由 ash 在运行期 dlopen，不参与 ELF 求解，RPATH 无效，
    # 只能经 LD_LIBRARY_PATH 提供。
    mv $out/bin/waywallen-layer-shell $out/bin/.waywallen-layer-shell
    makeWrapper $out/bin/.waywallen-layer-shell $out/bin/waywallen-layer-shell \
      --prefix LD_LIBRARY_PATH : ${vulkan-loader}/lib

    runHook postInstall
  '';

  meta = with lib; {
    description = "Wayland layer-shell helper (prebuilt binary)";
    mainProgram = "waywallen-layer-shell";
    platforms = ["x86_64-linux"];
    sourceProvenance = [sourceTypes.binaryNativeCode];
  };
}
