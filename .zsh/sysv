#
# SystemV 
#

case $(uname) in
Linux)
  if [ "$PS1" ]; then
    alias ls='ls -CF --color'
    alias la='ls -a'
    alias ll='ls -lh'
    alias l='ls -alh'
    alias psg='ps -ef | grep -v grep | grep -v "ps -ef" | grep'
    alias nsg='netstat -tulpen | grep'
    alias grep="grep --exclude-dir=.svn --color"
  fi
;;
esac
