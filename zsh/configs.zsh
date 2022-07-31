#################################  HISTORY  #################################
# history
HISTFILE=$HOME/.zsh-history 	# 履歴を保存するファイル
HISTSIZE=100000             	# メモリ上に保存する履歴のサイズ
SAVEHIST=1000000            	# 上述のファイルに保存する履歴のサイズ

# share .zshhistory
setopt inc_append_history   	# 実行時に履歴をファイルにに追加していく
setopt share_history        	# 履歴を他のシェルとリアルタイム共有する

setopt hist_ignore_all_dups 	# ヒストリーに重複を表示しない
setopt hist_save_no_dups    	# 重複するコマンドが保存されるとき、古いほうを削除する
setopt extended_history     	# コマンドのタイムスタンプをHISTFILEに記録する
setopt hist_expire_dups_first	# HISTFILEのサイズがHISTSIZEを超える場合は、最初に重複を削除する

#################################  COMPLEMENT  #################################
# enable completion
autoload -Uz compinit && compinit

autoload -Uz colors && colors

# 補完候補をそのまま探す -> 小文字を大文字に変えて探す -> 大文字を小文字に変えて探す
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'

### 補完方法毎にグループ化する。
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''


### 補完侯補をメニューから選択する。
### select=2: 補完候補を一覧から選択する。補完候補が2つ以上なければすぐに補完する。
zstyle ':completion:*:default' menu select=2

# ファイル保管候補に色を付ける
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

#################################  OTHERS  #################################
# automatically change directory when dir name is typed
setopt auto_cd

# disable ctrl+s, ctrl+q
setopt no_flow_control

# ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt auto_param_slash

# カッコを自動補完
setopt auto_param_keys

# ファイル名の展開でディレクトリにマッチした場合 末尾に / を付加
setopt mark_dirs

# 補完キー連打で順に補完候補を自動で補完
setopt auto_menu

# スペルミス訂正
setopt correct

# コマンドラインでも # 以降をコメントと見なす
setopt interactive_comments

# コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt magic_equal_subst

# 語の途中でもカーソル位置で補完
setopt complete_in_word

# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# ビープ音を消す
setopt no_beep

# lsコマンドのalias関連
alias ls='ls --color=auto -G'
alias la='ls -lAG'
alias ll='ls -lG'

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

## コマンド履歴検索
function peco-history-selection() {
    BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

function peco-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | peco --prompt="cdr >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}
zle -N peco-cdr
bindkey '^E' peco-cdr

#if test $(service docker status | awk '{print $4}') = 'not'; then
#	sudo /usr/sbin/service docker start
#fi

## Win_user
if [ "$(uname 2> /dev/null)" = Linux ]; then
  if [[ "$(uname -r 2> /dev/null)" = *microsoft* ]]; then
    export PATH="$PATH:$WIN_PATH:$(/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0//powershell.exe '$env:PATH' | sed -e 's/C:/\/mnt\/c/g' -e 's/\\/\//g' -e 's/;/:/g' | iconv -f sjis -t utf8)"
    typeset -U path PATH
    export WIN_USERNAME=$(powershell.exe '$env:USERNAME' | sed -e 's/\r//g')
    export WIN_USERHOME=/mnt/c/Users/$WIN_USERNAME
  fi
fi
## ssh
export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
ss -a | grep -q $SSH_AUTH_SOCK
if [ $? -ne 0   ]; then
    rm -f $SSH_AUTH_SOCK
    ( setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
fi
