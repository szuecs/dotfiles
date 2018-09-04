#
# basic config with nifty functions
#

# If running interactively, then:
if [ "$PS1" ]; then
  # ssl inspect
  #export SSLKEYLOGFILE=$HOME/ssllog/ssl-log.txt

  # clean all aliases
  unhash -am '*'

  # nice ri
  export RI="--no-pager -f ansi"

  # alias section
  alias la='ls -a'
  alias ll='ls -lh'
  alias l='ls -lah'
  # return your external visible IP
  alias myip='curl readmyip.appspot.com'
  # fix hyphen sort problem
  alias sort='LC_ALL=C sort'
  # vim restore session
  alias vimo="vim -S ~/.vim/sessions/last.vim"
  # with mmv u can rename multiple files. mmv *.text *.txt
  alias mmv='noglob zmv -W'
  autoload -U zmv

  # set different colors on STDERR
  autoload -U colors
  colors
  #exec 2>>(while read line; do
  #  print "$fg[blue]${(q)line}" > /dev/tty; done & )
  #print "$bg[black]$fg[red]${(q)line}" > /dev/tty; done &)

  # edit CLI with your favorite Editor
  autoload edit-command-line
  zle -N edit-command-line
  bindkey '^X^e' edit-command-line

  # bind C-s to search forward in history
  #autoload history-search-forward
  #zle -N history-search-forward
  #bindkey '^s' history-search-forward

  # history related stuff.
  export HISTSIZE=10500
  export SAVEHIST=10000
  export HISTFILE=~/.zsh_history
  setopt hist_ignore_dups        # ignore same commands run twice+
  setopt appendhistory           # do not overwrite history
  setopt histignorespace         # remove command lines from the history list when
  setopt histverify              # when using ! cmds, confirm first
#  setopt SHARE_HISTORY
  setopt EXTENDED_HISTORY
  setopt hist_ignore_all_dups
  setopt HIST_REDUCE_BLANKS
  # Grep the history with 'h'
  h () { history 0 | grep $1 }

  # use ssh for rysnc
  export RSYNC_RSH=ssh

  export PAGER=less
  export ALTERNATE_EDITOR=emacs
  export EDITOR=emacsclient
  export VISUAL=emacsclient
  # emacs
  export GDK_NATIVE_WINDOWS=1
  alias e="$EDITOR -c $@"

  #alias e='exec emacsclient --alternate-editor="" -c "$@"'
  #tempuid=`id -u`
  #temphost=`hostname`
  #if [ ! -e "/tmp/esrv$tempuid-$temphost" ]; then
  #    emacs --daemon
  #fi

  # support colors in less
  export LESS_TERMCAP_mb=$'\E[01;31m'
  export LESS_TERMCAP_md=$'\E[01;31m'
  export LESS_TERMCAP_me=$'\E[0m'
  export LESS_TERMCAP_se=$'\E[0m'
  export LESS_TERMCAP_so=$'\E[01;44;33m'
  export LESS_TERMCAP_ue=$'\E[0m'
  export LESS_TERMCAP_us=$'\E[01;32m'

  # add -rrubygems to all ruby starts
  export RUBYOPT="rrubygems"

  # nifty aliases
  alias -g L='2>&1 | less -R'
  alias -g G='2>&1 |grep'
  alias -g H='|head -15'
  alias -g S='|sort'
  alias -g W='|wc -l'
  # file extension aliases (open with)
  alias -s zip="zipinfo"
  alias -s txt="less"
  alias -s pp="emacs"
  alias -s tex="emacs"
  alias -s c="emacs"
  # quick edit
  alias z="$EDITOR -c ~/.zsh"

  # history cmd expansion using space, example: !-3␣
  bindkey ' ' magic-space
  # forward / backward word with C-<left> C-<right>
  bindkey '^[[1;5C' emacs-forward-word
  bindkey '^[[1;5D' emacs-backward-word

  # Quote pasted URLs
  autoload url-quote-magic
  zle -N self-insert url-quote-magic

  #export=WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

fi

