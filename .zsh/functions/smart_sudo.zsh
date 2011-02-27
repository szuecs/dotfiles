# Give us a root shell, or run the command with sudo.
# Expands command aliases first (cool!)
smart_sudo () {
  if [[ -n $1 ]]; then
      #test if the first parameter is a alias
      if [[ -n $aliases[$1] ]]; then
          #if so, substitute the real command
          sudo ${=aliases[$1]} $argv[2,-1]
      else
          #else just run sudo as is
          sudo $argv
      fi
  else
      #if no parameters were given, then assume we want a root shell
      sudo -s
  fi
}
alias s=smart_sudo
compdef _sudo smart_sudo
