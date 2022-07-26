#!/bin/bash
set -e
echo -n "password :"
read -sr PASS

echo "$PASS" | sudo -S apt-get update -y
echo "$PASS" | sudo -S apt-get dist-upgrade -y
echo "$PASS" | sudo -S apt-get autoremove -y

## Win_user
if [ "$(uname 2>/dev/null)" = Linux ]; then
	if [[ "$(uname -r 2>/dev/null)" = *microsoft* ]]; then
		WIN_USERNAME=$(powershell.exe '$env:USERNAME' | sed -e 's/\r//g')
		WIN_USERHOME=/mnt/c/Users/$WIN_USERNAME
	fi
fi

has() {
	type "$1" >/dev/null 2>&1
}

## dotfiles
DOT_DIRECTORY="${HOME}/dotfiles"
DOT_TARBALL="https://github.com/tadi-karuma/dotfiles/tarball/master"
REMOTE_URL="https://github.com/tadi-karuma/dotfiles.git"

if [ ! -d "${DOT_DIRECTORY}" ]; then
	echo "Downloading dotfiles..."
	rm -rf "${DOT_DIRECTORY}"
	mkdir "${DOT_DIRECTORY}"
	if has "git"; then
		git clone --recursive "${REMOTE_URL}" "${DOT_DIRECTORY}"
	else
		curl -fsSLo "${HOME}/dotfiles.tar.gz ${DOT_TARBALL}"
		tar -zxf "${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOT_DIRECTORY}"
		rm -f "${HOME}/dotfiles.tar.gz"
	fi
	echo "$(tput setaf 2)Download dotfiles complete!. $(tput sgr0)"
fi

cd "${DOT_DIRECTORY}"
for f in .??*; do
	[[ ${f} = ".git" ]] && continue
	[[ ${f} = ".gitignore" ]] && continue
	ln -snfv "${DOT_DIRECTORY}/${f}" "${HOME}/${f}"
done
echo "$(tput setaf 2)Deploy dotfiles complete!. $(tput sgr0)"

echo "$PASS" | sudo -S apt install socat -y
echo "$PASS" | sudo -S apt install peco -y
echo "$PASS" | sudo -S apt install zsh -y

## ssh_host
if ! ls /etc/ssh/ssh_host_*_key >/dev/null 2>&1; then
	echo "$PASS" | sudo -S ssh-keygen -A
fi
SSH_STATUS=$(service ssh status | awk '{print $4}')
if [ "$SSH_STATUS" = "not" ]; then
	echo "$PASS" | sudo -S service ssh start >/dev/null
fi

## ssh_user
if [ ! -d ~/.ssh ]; then
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
fi
AUT_KEY=$HOME/.ssh/authorized_keys
WSL_PUB=$(cat "$WIN_USERHOME/.ssh/wsl_ed25519.pub")
if ! grep -xq "${WSL_PUB}" "${AUT_KEY}"; then
	echo "$WSL_PUB" >>"$AUT_KEY" && chmod 600 "$AUT_KEY"
fi

WSL_CONF=/etc/wsl.conf
if [ ! -f "$WSL_CONF" ]; then
	echo "$PASS" | sudo -S touch "$WSL_CONF"
fi

SSH_BOOT=$(echo -n "/usr/sbin/service ssh start")
if ! grep -q "${SSH_BOOT}" "${WSL_CONF}"; then
	if grep -q "[boot]" "${WSL_CONF}"; then
		echo "$PASS" | sudo -S sed -i -e "/\[boot\]/a ${SSH_BOOT}" "$WSL_CONF"
	else
		echo "$PASS" | sudo -S sed -i -e "\$a \[boot\]\n${SSH_BOOT}" "$WSL_CONF"
	fi
fi

[ "${SHELL}" != "/bin/zsh" ] && chsh -s /bin/zsh
echo "$(tput setaf 2)Initialize complete!. $(tput sgr0)"
