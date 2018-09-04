case $(uname) in
Linux)
  #export PATH="/server/bin:$PATH"
  export JAVA_HOME=/usr/lib/jvm/default-java

  pidof syndaemon &>/dev/null
  if [ ! $? -eq 0 ]
  then
      bash -c 'syndaemon -i 0.25 -R &' # disable trackpad while typing
  fi

  if [ "$PS1" ]; then
      alias R="R -q"
      if which nautilus >/dev/null && (pgrep gdm >/dev/null || pgrep lightdm >/dev/null); then


function open_pdf() {
  if  which evidence 2>/dev/null; then
    evidence $1 2>/dev/null &
  elif which evince 2>/dev/null; then
    evince $1 2>/dev/null &
  elif which acroread 2>/dev/null; then
    acroread $1 2>/dev/null &
  fi
}

function open_browser () {
  if  which firefox 2>/dev/null; then
    firefox $1 2>/dev/null &
  elif which chromium-browser 2>/dev/null; then
    chromium-browser $1 2>/dev/null &
  else
    echo "no browser found to open ${$1}"
  fi
}

function open_office () {
  if  which libreoffice 2>/dev/null; then
      libreoffice $1 &
  else
      echo "no Office found to open ${1}"
  fi
}

# A zsh function similar to Mac OSX open(1) command.
function open() {
  file_path=$1
  file_ext=$(echo $1 | awk -F. '{print $NF}')

  if [ -L $file_path ]; then
    file_path=$(readlink $file_path)
  fi
  target_file=$(file $file_path | sed -e 's/.*: //')
  first_word=$(echo $target_file | awk '{print $1}')
  second_word=$(echo $target_file | awk '{print $2}')

  for word in $file_ext $first_word $second_word; do
    case $word in
    directory)     nautilus $1 ;;
    text)          emacs $1    ;;
    image)         eog $1      ;;
    gimp)          gimp $1     ;;
    pdf|PDF)       open_pdf $1 ;;
    html|HTML|svg|SVG)
                   open_browser $1 ;;
    ods|ODS|odp)   open_office $1 ;;
    *)
      echo "nothing found to open ${1}, ${target_file},${first_word}, ${second_word}"
      ;;;
    esac
  done
}

     fi
  fi
;;
esac

