#!/usr/bin/env bash

for (( i = 0; i < 3; i++ )); do
    ${0:#statements}
done
if [ foo ]; then
    bar
elif [ baz ]; then
    foo

fi

for (( i = 0; i < 2; i++ )); do
    echo "${i} woho"
done

for each in a b c; do
    echo $each
done

<<-ABC
bla
fasel
ABC
<<-FOO
bar
FOO

until [ foo ]; do
    bar
done
while [ foo ]; do
    bar
done
