# ~/.config/fish/config.fish

## Greeting
function fish_greeting
    fastfetch
end

## Environment & Pager
# Format man pages using bat
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Append common binary locations to PATH
fish_add_path ~/.local/bin ~/.cargo/bin

# Source ~/.fish_profile if present
if test -f ~/.fish_profile
    source ~/.fish_profile
end

## CachyOS Bang-Bang Functions (enables !! and !$)
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

## Utility Functions
# Fish command history with timestamps
function history
    builtin history --show-time='%F %T ' $argv
end

# Quick file backup: `backup filename.txt` creates `filename.txt.bak`
function backup --argument filename
    cp $filename $filename.bak
end

# Safe directory copy
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

## Aliases
# Replace ls with eza
alias ls='eza -al --color=always --group-directories-first --icons=always'
alias la='eza -a --color=always --group-directories-first --icons=always'
alias ll='eza -l --color=always --group-directories-first --icons=always'
alias lt='eza -aT --color=always --group-directories-first --icons=always'
alias l.="eza -a | grep -e '^\.'"

# Quick directory traversal
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Nobara / Fedora package management equivalents
alias update='sudo dnf upgrade --refresh'
alias cleanup='sudo dnf autoremove'
alias grubup='sudo grub2-mkconfig -o /boot/grub2/grub.cfg'

# System utilities
alias jctl="journalctl -p 3 -xb"
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias grep='grep --color=auto'
alias tb='nc termbin.com 9999'
