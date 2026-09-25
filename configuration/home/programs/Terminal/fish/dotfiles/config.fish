if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
alias ls='eza --icons=auto'
alias ll='eza -l --icons=auto'
alias la='eza -a --icons=auto'
alias l='eza -la --icons=auto'
alias lt='eza -T --icons=auto'
alias lta='eza -Ta --icons=auto'
starship init fish | source
