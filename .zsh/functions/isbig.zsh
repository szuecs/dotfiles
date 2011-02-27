# big-endian or little-endian ? 
# Tested on: Mac G4 and macbbook.
isbig () {
  isBIG=`/usr/bin/perl -e 'printf(unpack("h*", pack("s", 1)) =~ /01/);'`
  if [ $isBIG -eq 1 ]; then 
    print "BIG_ENDIAN"; 
  else
    print "LITTLE_ENDIAN"
  fi
}
