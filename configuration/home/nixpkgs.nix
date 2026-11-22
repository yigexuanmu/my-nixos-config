# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/home.nix
#   下游（本文件引用）：无
#   相关（语义关联）：
#     - configuration/system/nix.nix（系统/Home 两侧 nixpkgs 配置分工）
#     - configuration/system/overlays.nix（系统侧 overlay）
# ────────────────────────────────────────────────────────────

{
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      pipx = prev.pipx.overridePythonAttrs (old: {
    doCheck = false;
  });
    })
  ];

  # 仅 Home 作用域: pnpm-10 与 electron 由用户级包引入
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
    "pnpm-10.29.2"
  ];

  nixpkgs.config.allowUnfree = true;
}
