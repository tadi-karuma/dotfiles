#!/bin/bash

dotfiles=(.zshrc)

for file in "${dotfiles[@]}"; do
	ln -svf $file ~/
done

