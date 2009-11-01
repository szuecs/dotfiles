#! /bin/zsh
##############################
### print function
### by sandor szuecs Dec 2006
### print function, because it's boring to convert pdf to ps, scp it and ssh ...
###
### usage: print-on queue_name file.{ps,pdf}
##############################

#INF="szuecs@xian.mi.fu-berlin.de"
INF="szuecs@wuhan.mi.fu-berlin.de"
MATH="szuecs@jordan.mi.fu-berlin.de"

typeset -A QUEUE_LIST HOST_LIST
QUEUE_LIST=(
	"math" "a6-030-edu"
	"mathe" "a6-030-edu"
	"a2central" "a6-030-edu"
	"A2central" "a6-030-edu"
	"inf" "t9-k42-edu"
	"ldu" "t9-k42-edu"
	"lsi" "t9-k42-edu -o sides=one-sided" 
)
HOST_LIST=(
	"math" "$MATH"
	"mathe" "$MATH"
	"a2central" "$MATH"
	"A2central" "$MATH"
	"inf" "$INF"
	"ldu" "$INF"
	"lsi" "$INF"
)

print-on () {

	if [[ -n $1 && -f $2 ]]; then
		# falls pdf dann nach ps uebersetzen
		if [[ $2:e == "pdf" ]]; then
			pdf2ps $2
			FILE=$2:r
			FILE=$FILE.ps
			FILE=$FILE:t
		elif [[ $2:e == "ps" ]]; then
			print "data is .ps, so I try to print it now"
			FILE=$2
		else
			print "unknown file extension. I can not print a .$2:e file"
		fi

 		if [[ $QUEUE_LIST[$1] == "a6-030-edu" ]]; then
 		elif [[ $QUEUE_LIST[$1] == "t9-k42-edu -o sides=one-sided" || 
						$QUEUE_LIST[$1] == "t9-k42-edu" ]]; then
 		else
 			print "unknown queue name $1"
 			return 1
 		fi

	print "print on $QUEUE_LIST[$1]"
	print "print with $HOST_LIST[$1]"

		cat $FILE | ssh $HOST_LIST[$1] "lpr -P $QUEUE_LIST[$1] && lpq -P $QUEUE_LIST[$1]"
		if [[ $2:e == "pdf" ]]; then
			rm $FILE
		fi
	else
		print "$1 $2"
		print "usage: print_on queue file.pdf"
	fi
}


