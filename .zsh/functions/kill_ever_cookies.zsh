function kill_ever_cookie () {
  echo "Deleting evercookie locations"
  rm -r ~/Library/Safari/Databases/*
  rm -r ~/Library/Safari/LocalStorage/*
  rm -r ~/Library/Preferences/Macromedia/Flash\ Player/\#SharedObjects/*
}
