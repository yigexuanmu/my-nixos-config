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

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
    "pnpm-10.29.2"
  ];

  nixpkgs.config.allowUnfree = true;
}
