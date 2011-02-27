#Author: Copyright (c) 2005 Eric Mangold - teratorn (at) world (dash) net (dot) net
#License: MIT. http://www.opensource.org/licenses/mit-license.html
extract_archive () {
  local old_dirs current_dirs lower
  lower=${(L)1}
  old_dirs=( *(N/) )
  if [[ $lower == *.tar.gz || $lower == *.tgz ]]; then
      tar zxfv $1
  elif [[ $lower == *.gz ]]; then
      gunzip $1
  elif [[ $lower == *.tar.bz2 || $lower == *.tbz ]]; then
      bunzip2 -c $1 | tar xfv -
  elif [[ $lower == *.tar.xz || $lower == *.txz ]]; then
      xz -d -c $1 | tar xfv -
  elif [[ $lower == *.bz2 ]]; then
      bunzip2 $1
  elif [[ $lower == *.zip ]]; then
      unzip $1
  elif [[ $lower == *.rar ]]; then
      unrar e $1
  elif [[ $lower == *.tar ]]; then
      tar xfv $1
  elif [[ $lower == *.lha ]]; then
      lha e $1
  elif [[ $lower == *.xz ]]; then
      xz -d $1
  else
      print "Unknown archive type: $1"
      return 1
  fi
  # Change in to the newly created directory, and
  # list the directory contents, if there is one.
  current_dirs=( *(N/) )
  for i in {1..${#current_dirs}}; do
      if [[ $current_dirs[$i] != $old_dirs[$i] ]]; then
          cd $current_dirs[$i]
          ls
          break
      fi
  done
}
alias ex=extract_archive
compdef '_files -g "*.gz *.tgz *.bz2 *.tbz *.zip *.rar *.tar *.lha *.xz *.txz"' extract_archive
