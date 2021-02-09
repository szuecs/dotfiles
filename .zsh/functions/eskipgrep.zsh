function eskipgrep () {
	eskip print $2 | grep $1 | eskip print --pretty
}
