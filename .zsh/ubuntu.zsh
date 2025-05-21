case $(uname) in
Linux)

function snap_clean() {
	LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
		while read pkg revision; do
	  sudo snap remove "$pkg" --revision="$revision"
	done
}

;;
esac

