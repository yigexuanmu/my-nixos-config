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
