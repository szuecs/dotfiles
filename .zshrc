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

# rvm - needs zsh >= 4.3.5, but there is 4.3.4 installed on osx 10.5
# use zsh-devel from macports
if [[ -s /usr/local/rvm/scripts/rvm ]] ; then source /usr/local/rvm/scripts/rvm ; fi
