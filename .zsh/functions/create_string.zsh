#
# create_string <charsequence> <len>
#
#
function create_string () {
        ruby -e "print(\"$1\" * $2)"
}
