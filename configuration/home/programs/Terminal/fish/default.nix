{
  ...
}: {
  # 通过 programs.fish 管理（而非 xdg.configFile），
  # starship 初始化由 programs.starship 自动注入
  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
    alias ls='eza --icons --'
    alias ll='eza -l --icons --'
    alias la='eza -a --icons --'
    alias l='eza -la --icons --'
    alias lt='eza -T --icons --'
    alias lta='eza -Ta --icons --'
  '';
}
