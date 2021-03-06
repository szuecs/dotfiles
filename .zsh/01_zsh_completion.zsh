if [ "$PS1" ]; then
  test -d $HOME/.zsh/cache || mkdir $HOME/.zsh/cache

  # complist section
  zmodload -i zsh/complist

  setopt autocd                  # change to dirs without cd
  setopt extendedglob            # weird & wacky pattern matching - yay zsh!
  setopt completeinword          # not just at the end
  setopt alwaystoend             # when complete from middle, move cursor
  setopt nopromptcr              # don't add \n which overwrites cmds with no \n
  setopt interactivecomments     # escape commands so i can use them later
  setopt printexitvalue          # alert me if something's failed
  setopt noshwordsplit           # use zsh style word splitting

  # autocd expanding
  #cdpath=(. $GOROOT/src $GOPATH/src/golang.org $GOPATH/src/github.com $GOPATH/src/github.com/szuecs)
  cdpath=(. $GOROOT/src $GOPATH/src/golang.org $GOPATH/src/github.com $GOPATH/src/github.com/szuecs $GOPATH/src/github.bus.zalan.do/teapot $GOPATH/src/github.com/zalando $GOPATH/src/github.com/zalando-incubator)

  # custom completions
  fpath=($HOME/.zsh/Completion $fpath)
  # https://github.com/zsh-users/zsh-completions
  fpath=($HOME/.zsh/zsh-completions/src $fpath)

  #
  # completion tweaking
  #
  autoload -U compinit; compinit
  autoload -U bashcompinit && bashcompinit
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path $HOME/.zsh/cache
  zstyle ':completion:*' users resolve
  # activate menu selection if >=5 possibilities
  zstyle ':completion:*' menu select=5
  # use dircolours in completion listings
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  # format all messages not formatted in bold prefixed with ----
  zstyle ':completion:*' format '%B---- %d%b'
  # format descriptions (notice the vt100 escapes)
  zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'
  # bold and underline normal messages
  zstyle ':completion:*:messages' format '%B%U---- %d%u%b'
  # format in bold red error messages
  zstyle ':completion:*:warnings' format "%B$fg[red]%}---- no match for: $fg[white]%d%b"
  # let's use the tag name as group name
  zstyle ':completion:*' group-name ''
  # activate approximate completion, but only after regular completion (_complete)
  # and matching (_match)
  zstyle ':completion:*' completer _complete _match _approximate
  # limit to 2 errors
  zstyle ':completion:*:approximate:*' max-errors 2
  # let's complete known hosts and hosts from ssh's known_hosts file
  #basehost="host1.example.com host2.example.com"
  hosts=(
    $(
      (
        ( [ -r .ssh/known_hosts ] && awk '{print $1}' .ssh/known_hosts | tr , '\n');
        echo $basehost; ) | sort -u | grep -v \|1\| ))
  zstyle ':completion:*' hosts $hosts

  zstyle ':completion:*:vi:*' ignored-patterns '*.(o|a|so|dmg|dylib|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pyc|rbc|dSYM)'
  zstyle ':completion:*:vim:*' ignored-patterns '*.(o|a|so|dmg|dylib|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pyc|rbc|dSYM)'
  zstyle ':completion:*:mate:*' ignored-patterns '*.(o|a|so|dmg|dylib|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pyc|rbc|dSYM)'
  zstyle ':completion:*:emacs:*' ignored-patterns '*.(o|a|so|dmg|dylib|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pyc|rbc|dSYM)'
  zstyle ':completion:*:emacsclient:*' ignored-patterns '*.(o|a|so|dmg|dylib|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pyc|rbc|dSYM)'
  zstyle ':completion:*:e:*' ignored-patterns '*.(o|a|so|dmg|dylib|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pyc|rbc|dSYM)'

fi
