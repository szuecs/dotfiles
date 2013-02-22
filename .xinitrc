eval $(gpg-agent --daemon)
xmodmap -e "keycode 133 = Super_L" -e "add mod4 = Super_L"
#xmodmap -e "keycode 115 = Super_L" -e "add mod4 = Super_L"
exec awesome
