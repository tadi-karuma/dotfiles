# ZI
source <(curl -sL https://git.io/zi-loader); zzinit
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi

# Created by newuser for 5.8.1
#

SCRIPT_DIR="${HOME}/.dotfiles"

source "${SCRIPT_DIR}/zsh/plugins.zsh"
#source "${SCRIPT_DIR}/zsh/p10k.zsh"
source "${SCRIPT_DIR}/zsh/configs.zsh"
