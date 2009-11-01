# prints sequence on STDOUT
# $ seq 1 10 
# 1 2 3 4 5 6 7 8 9 10
function seq () {
        ruby -e "puts (\"$1\"..\"$2\").to_a.join(' ')"
}
