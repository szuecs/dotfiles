# .zshrc includes all different files in .zsh
# 

umask 077
export PS1='[%n@%m:%~]$ '

if [ -d ~/.zsh ]; then
	for each in ~/.zsh/*; do
		if [[ -f $each && $each:e != "off" ]]; then 
			. $each
		fi
	done
	## functions
	if [ -d ~/.zsh/functions ]; then
		for each in ~/.zsh/functions/*
			if [[ -f $each && $each:e != "off" ]]; then 
				. $each
			fi
	fi
fi
