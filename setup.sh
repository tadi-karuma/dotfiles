#!/bin/bash

dotfiles=(.zshrc)

for files in "${dotfiles[@]}"; do
	ln -svf $files ~/
done

