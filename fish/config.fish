fish_config theme choose rime
set -g fish_greeting

set -gx EDITOR vis
set -gx BROWSER librewolf

set -gx ANDROID_HOME ~/Android/Sdk
# fish_add_path skips folders that don't exist, so this is safe on any machine
fish_add_path -g ~/.local/bin ~/.cargo/bin ~/go/bin ~/.dotnet/tools \
    $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools $ANDROID_HOME/emulator

# man pages in color through bat
set -gx MANROFFOPT -c
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

# listing, needs eza
alias ls='eza -a --color=always --group-directories-first'
alias lt='eza -aT --color=always --group-directories-first'

# git
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit -m'
alias gb='git branch -a'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
# rime colors: blue paths, purple line numbers, yellow matches
alias rgrep='rg --colors=path:fg:0x7a,0xa4,0xe4 --colors=line:fg:0xbb,0x98,0xd6 --colors=column:fg:0xbb,0x98,0xd6 --colors=match:fg:0xe4,0xd0,0x98'

alias h='eval "$(horse)"'
