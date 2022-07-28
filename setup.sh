#!/bin/bash
read -s -p "press password :" PASS

echo $PASS | sudo -S apt update -y
echo $PASS | sudo -S apt upgrade -y
echo $PASS | sudo -S apt autoremove -y

set -e
DOT_DIRECTORY="${HOME}/dotfiles"
DOT_TARBALL="https://github.com/tadi-karuma/dotfiles/tarball/master"
REMOTE_URL="https://github.com/tadi-karuma/dotfiles.git"

has() {
	type "$1" > /dev/null 2>&1
}

if [ ! -d ${DOT_DIRECTORY} ]; then
	echo "Downloading dotfiles..."
	rm -rf ${DOT_DIRECTORY}
	mkdir ${DOT_DIRECTORY}
	if has "git"; then
		git clone --recursive "${REMOTE_URL}" "${DOT_DIRECTORY}"
	else
		curl -fsSLo ${HOME}/dotfiles.tar.gz ${DOT_TARBALL}
		tar -zxf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOT_DIRECTORY}
		rm -f ${HOME}/dotfiles.tar.gz
	fi
	echo $(tput setaf 2)Download dotfiles complete!. $(tput sgr0)
fi


## Win_user
if [ "$(uname 2> /dev/null)" = Linux ]; then
  if [[ "$(uname -r 2> /dev/null)" = *microsoft* ]]; then
    export WIN_USERNAME=$(powershell.exe '$env:USERNAME' | sed -e 's/\r//g')
    export WIN_USERHOME=/mnt/c/Users/$WIN_USERNAME
  fi
fi

## ssh_host
SSH_HOST_KEY_FILE="/etc/ssh/ssh_host_ed25519_key"

if [ ! -e $SSH_HOST_KEY_FILE ];then
	echo $PASS | sudo ssh-keygen -A
fi

if [ $(service ssh status | awk '{print $4}') = "not" ]; then
	echo $PASS | sudo service ssh start > /dev/null
fi

## ssh_user

if [ ! -d ~/.ssh ];then
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
fi

AUT_KEY=$HOME/.ssh/authorized_keys
SSH_PUB=$(cat "$WIN_USERHOME/.ssh/wsl_ed25519.pub")

if [ -e $AUT_KEY ];then
	if grep -x -q "${SSH_PUB}" "${AUT_KEY}" ;then
		:
	else
		echo $SSH_PUB >> $AUT_KEY && chmod 600 $AUT_KEY
	fi
else
	echo $SSH_PUB >> $AUT_KEY && chmod 600 $AUT_KEY
fi

echo $PASS | sudo -S apt install socat -y
echo $PASS | sudo -S apt install peco -y
echo $PASS | sudo -S apt install zsh -y

cd ${DOT_DIRECTORY}

for f in .??*
do
  [[ ${f} = ".git" ]] && continue
  [[ ${f} = ".gitignore" ]] && continue
  [[ ${f} = "setup.sh" ]] && continue
  [[ ${f} = "zsh" ]] && continue
  ln -snfv ${DOT_DIRECTORY}/${f} ${HOME}/${f}
done
echo $(tput setaf 2)Deploy dotfiles complete!. $(tput sgr0)

[ ${SHELL} != "/bin/zsh"  ] && chsh -s /bin/zsh
echo "$(tput setaf 2)Initialize complete!. $(tput sgr0)"
