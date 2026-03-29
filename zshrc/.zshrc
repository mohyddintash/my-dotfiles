# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
#if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
#  source /usr/share/zsh/manjaro-zsh-prompt
#fi


# go lang
export PATH=$PATH:/usr/local/go/bin


# Golang environment variables
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH:



# Load pyenv automatically by appending
# the following to 
# ~/.bash_profile if it exists, otherwise ~/.profile (for login shells)
# and ~/.bashrc (for interactive shells) :

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Restart your shell for the changes to take effect.

# Load pyenv-virtualenv automatically by adding
# the following to ~/.bashrc:

eval "$(pyenv virtualenv-init -)"

yt_transcript() {
    if [ $# -eq 0 ]; then
        echo "Usage: yt_transcript <YouTube URL>"
        return 1
    fi

    # Combine all arguments into a single URL
    local url="$*"
    # Pass the URL to the yt command
    yt "${url}" | jq -r ".transcript" | xclip -selection clipboard
    echo "Transcript copied to clipboard."
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/usr/bin:$PATH"

echo ".zshrc was sourced!"


HISTFILE=~/.history
HISTSIZE=10000
SAVEHIST=50000

setopt inc_append_history

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(starship init zsh)"
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PGHOST="/var/run/postgresql"



# bun completions
[ -s "/home/mo/.bun/_bun" ] && source "/home/mo/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit


alias zeditor="DRI_PRIME=1 WAYLAND_DISPLAY="" zeditor"

alias handbrake="DRI_PRIME=1 WAYLAND_DISPLAY="" flatpak run fr.handbrake.ghb"

# Gemini sandbox
#alias geminiai="firejail --private=~/firejail-sandbox gemini"
alias gemini="gemini --sandbox"
alias geminiai='firejail --private=~/firejail-sandbox/ --profile=/home/mo/.config/firejail/gemini.profile /home/mo/.nvm/versions/node/v23.5.0/bin/node /home/mo/.nvm/versions/node/v23.5.0/bin/gemini'
#fabric -y "https://www.youtube.com/watch?v=YtaR_I65wmI" --stream --pattern summarize
#fabric -y "https://www.youtube.com/watch?v=YtaR_I65wmI" --stream --pattern extract_wisdom
# fabric -y "https://www.youtube.com/watch?app=desktop&v=IBg1NwctLVY&t=0s" --stream --pattern extract_ideas | cliphist store

## default .config: ~/.config/nvim
## multiple .configs: ~/.config/nvim-_

alias nvim-lazy='NVIM_APPNAME="nvim-lazyvim" nvim'
# rm -rf ~/.config/nvim-lazyvim ~/.local/share/nvim-lazyvim ~/.cache/nvim-lazyvim ~/.local/state/nvim-lazyvim

alias nvim-nvchad='NVIM_APPNAME="nvim-nvchad" nvim'
# rm -rf ~/.config/nvim-nvchad ~/.local/share/nvim-nvchad ~/.cache/nvim-nvchad ~/.local/state/nvim-nvchad

alias nvim-astro='NVIM_APPNAME="nvim-astronvim" nvim'
# rm -rf ~/.config/nvim-astronvim ~/.local/share/nvim-astronvim ~/.cache/nvim-astronvim ~/.local/state/nvim-astronvim

alias nvim-kickstart='NVIM_APPNAME="nvim-kickstart" nvim'
# rm -rf ~/.config/nvim-kickstart ~/.local/share/nvim-kickstart ~/.cache/nvim-kickstart ~/.local/state/nvim-kickstart

alias claude="/home/mo/.claude/local/claude"
