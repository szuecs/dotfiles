### ~/.zsh/macosx

case $(uname) in
"Darwin")
  export LC_CTYPE=en_US.UTF-8
  #export LC_CTYPE=de_DE.UTF-8

  # If running interactively, then:
  if [ "$PS1" ]; then

    X11="/usr/X11R6/bin"
    DEVTOOLS="/Developer/Tools:/Developer/usr/bin:/Developer/usr/sbin"
    PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$X11:$DEVTOOLS:/usr/libexec"
    MANPATH="/usr/local/share/man:$MANPATH"

    if [ ! $DISPLAY ]; then
      export DISPLAY=:0.0
    fi

    alias ls='ls -FGe'
    alias la='ls -a'
    alias ll='ls -lh'
    alias l='ls -lah'
    alias topp='top -s2 -o cpu -r'
    alias httphead="curl -I"
    alias psg='ps aux |grep -v grep | grep'
    alias psu='ps aux |grep -v grep | grep -v "^root " | grep -v "^nobody " | grep -v "^postfix " | grep -v "^windowse " |sort'
    alias grep='grep --color'
    alias kickstart='/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart'
    alias portclean="port installed |grep -v active | gawk -F ' ' '{print$1$2}' | xargs sudo port -f uninstall"
    alias airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport"
    alias ql='qlmanage -p 2>/dev/null'
    # Get readable list of network IPs
    alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
    alias myip="dig +short myip.opendns.com @resolver1.opendns.com"
    alias flush="dscacheutil -flushcache" # Flush DNS cache

    alias emacs='open -a Emacs.app --args'
    # set default of srm to overwrite blocks with 0x00
    alias srm="srm -z"
    alias r='/usr/local/bin/r'

    # JAVA
    JAVA_HOME='/System/Library/Frameworks/JavaVM.framework/Home'
    JAVA_OPTS='-Xms256m -Xmx1g'

##### osx functions
##### http://apple.stackexchange.com/questions/5435/got-any-tips-or-tricks-for-terminal-in-os-x
# open manpage in preview
pman () {
    man -t "${1}" | open -f -a /Applications/Preview.app
}
# open manpage in textmate
tman () {
  MANWIDTH=160 MANPAGER='col -bx' man $@ | mate
}
# Quit an OS X application from the command line
quit () {
  for app in $*; do
    osascript -e 'quit app "'$app'"'
  done
}
# Relaunch an app from the command line:
relaunch () {
    for app in $*; do
        osascript -e 'quit app "'$app'"';
        sleep 2;
        open -a $app
    done
}
# copy path of finder to shell output
function fp { osascript 2>/dev/null -e 'tell application "Finder"'\
 -e "if (${1-1} <= (count Finder windows)) then"\
 -e "get POSIX path of (target of window ${1-1} as alias)"\
 -e 'else' -e 'get POSIX path of (desktop as alias)'\
 -e 'end if' -e 'end tell'; };\
## alias to copy it to the clipboard
alias cfp='fp | pbcopy'

function sufinder {
  case $(uname -r) in
  "10.7.0")
    sudo /System/Library/CoreServices/Finder.app/Contents/MacOS/Finder
    ;;
  "10.8.0")
    sudo /System/Library/CoreServices/Finder.app/Contents/MacOS/Finder
    ;;
  esac
}
# Change directory to the directory shown in the top-most Finder window:
cdf () {
   currFolderPath=$( /usr/bin/osascript 2>/dev/null <<"         EOT"
       tell application "Finder"
           try
               set currFolder to (folder of the front window as alias)
           on error
               set currFolder to (path to desktop folder as alias)
           end try
           POSIX path of currFolder
       end tell
         EOT
   )
   echo "cd to \"$currFolderPath\""
   cd "$currFolderPath"
}



  fi
  ;; # close case
esac
