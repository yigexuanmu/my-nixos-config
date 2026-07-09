{
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.virt-manager.enable = true;
  programs.firefox.enable = true;
}
