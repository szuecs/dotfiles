function eskipgrep () {
	eskip print $2 | grep $1 | eskip print --pretty
}
function eskipgrepminusv () {
	eskip print $2 | grep -Ev $1 | eskip print --pretty
}
