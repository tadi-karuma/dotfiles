#!/bin/bash
set -e

# コマンドライン引数の解析
REBUILD=false
for arg in "$@"; do
    case "$arg" in
        --rebuild)
            REBUILD=true
            ;;
    esac
done

# パスワード入力（再利用可能に）
if [ -z "$PASS" ]; then
    echo -n "password :"
    read -sr PASS < /dev/tty
    echo
fi

# 環境作り直し時の削除処理
if $REBUILD; then
    echo "Rebuilding the environment..."
    echo "$PASS" | sudo -S apt-get remove --purge -y \
        socat peco zsh build-essential libffi-dev libssl-dev zlib1g-dev \
        liblzma-dev libbz2-dev libreadline-dev libsqlite3-dev libopencv-dev tk-dev git ssh
    rm -rf ~/.dotfiles ~/.pyenv ~/.ssh/authorized_keys
    echo "All configurations and installations have been removed."
fi

# 必要なパッケージの更新とクリーンアップ
if [ -z "$(sudo apt-get -s upgrade | grep '0 upgraded, 0 newly installed')" ]; then
    echo "$PASS" | sudo -S apt-get update -y
    echo "$PASS" | sudo -S apt-get dist-upgrade -y
    echo "$PASS" | sudo -S apt-get autoremove -y
fi

# dotfiles のデプロイ
DOT_DIRECTORY="${HOME}/.dotfiles"
DOT_TARBALL="https://github.com/tadi-karuma/dotfiles/tarball/master"
REMOTE_URL="https://github.com/tadi-karuma/dotfiles.git"

if [ ! -d "${DOT_DIRECTORY}" ] || $REBUILD; then
    echo "Downloading dotfiles..."
    rm -rf "${DOT_DIRECTORY}"
    mkdir "${DOT_DIRECTORY}"
    if type git >/dev/null 2>&1; then
        git clone --recursive "${REMOTE_URL}" "${DOT_DIRECTORY}"
    else
        curl -fsSLo "${HOME}/dotfiles.tar.gz" "${DOT_TARBALL}"
        tar -zxf "${HOME}/dotfiles.tar.gz" --strip-components 1 -C "${DOT_DIRECTORY}"
        rm -f "${HOME}/dotfiles.tar.gz"
    fi
    echo "$(tput setaf 2)Download dotfiles complete!$(tput sgr0)"
fi

cd "${DOT_DIRECTORY}"
for f in .??*; do
    [[ ${f} = ".git" ]] && continue
    [[ ${f} = ".gitignore" ]] && continue
    if [ ! -L "${HOME}/${f}" ] || [ "$(readlink ${HOME}/${f})" != "${DOT_DIRECTORY}/${f}" ]; then
        ln -snfv "${DOT_DIRECTORY}/${f}" "${HOME}/${f}"
    fi
done
echo "$(tput setaf 2)Deploy dotfiles complete!$(tput sgr0)"

# 必要なパッケージのインストール
PACKAGES=(
    socat peco zsh build-essential libffi-dev libssl-dev zlib1g-dev
    liblzma-dev libbz2-dev libreadline-dev libsqlite3-dev libopencv-dev tk-dev git ssh
)
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "$PASS" | sudo -S apt install -y "$pkg"
    fi
done

# pyenv のインストール
if [ ! -d ~/.pyenv ] || $REBUILD; then
    rm -rf ~/.pyenv
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
fi

# SSH ホストキーの設定
if ! ls /etc/ssh/ssh_host_*_key >/dev/null 2>&1; then
    echo "$PASS" | sudo -S ssh-keygen -A
fi
if ! service ssh status | grep -q "running"; then
    echo "$PASS" | sudo -S service ssh start >/dev/null
fi

# SSH 公開鍵の登録
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi
AUT_KEY="${HOME}/.ssh/authorized_keys"
WSL_PUB=$(powershell.exe "op item get 'wsl_ed25519' --field 'public key'" | tr -d '\r')
if [ -n "$WSL_PUB" ] && ! grep -Fxq "$WSL_PUB" "$AUT_KEY"; then
    echo "$WSL_PUB" >>"$AUT_KEY"
    chmod 600 "$AUT_KEY"
fi

# WSL 設定
WSL_CONF="/etc/wsl.conf"
SSH_BOOT="/usr/sbin/service ssh start"
if [ ! -f "$WSL_CONF" ]; then
    echo "$PASS" | sudo -S touch "$WSL_CONF"
fi
if ! grep -Fxq "$SSH_BOOT" "$WSL_CONF"; then
    if grep -q "\[boot\]" "$WSL_CONF"; then
        echo "$PASS" | sudo -S sed -i -e "/\[boot\]/a $SSH_BOOT" "$WSL_CONF"
    else
        echo "$PASS" | sudo -S bash -c "echo -e '[boot]\n$SSH_BOOT' >> $WSL_CONF"
    fi
fi

# デフォルトシェルの変更
if [ "${SHELL}" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
fi

echo "$(tput setaf 2)Initialize complete!$(tput sgr0)"
