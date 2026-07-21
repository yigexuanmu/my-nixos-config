{
  lib,
  stdenv,
  fetchFromGitHub,
  unzip,
}:

stdenv.mkDerivation rec {
  pname = "harmonyos-sans";
  version = "unstable-2023-02-26";

  src = fetchFromGitHub {
    owner = "huawei-fonts";
    repo = "HarmonyOS-Sans";
    rev = "33ab3b81b92c01f5e340c89960872bee174d8704";
    sha256 = "0afs1g56invxhn4jiq0yw53dmb8xwvi52h1k92047hw268rshsp2";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    runHook preUnpack
    unzip -q "$src/HarmonyOS Sans.zip" -d fonts
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    find fonts -name '*.ttf' -o -name '*.otf' | while read f; do
      install -Dm644 "$f" -t "$out/share/fonts/truetype"
    done
    runHook postInstall
  '';

  meta = with lib; {
    description = "HarmonyOS Sans - Huawei HarmonyOS font";
    homepage = "https://developer.huawei.com/consumer/cn/design/resource/";
    license = licenses.free;
    platforms = platforms.all;
  };
}
