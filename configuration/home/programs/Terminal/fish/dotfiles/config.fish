if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -a --icons'
alias l='eza -la --icons'
alias lt='eza -T --icons'
alias lta='eza -Ta --icons'
starship init fish | source
