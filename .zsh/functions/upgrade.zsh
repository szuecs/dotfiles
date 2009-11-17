##############################
### by sandor szuecs Dec 2006
### 
### upgrades local or remote: osx, debian or ubuntu systems
### usage local: $ upgrade 
### usage remote: $ upgrade $HOST
##############################
upgrade () {
	UMASK_RESTORE=`umask`
	umask 022
	if [ ! $1 ] ; then
		print "local upgrade"
		if [ `uname` = "Darwin" ]; then
			print "osx_upgrade_local"
			osx_upgrade_local
		elif [ `uname -o` = "GNU/Linux" ]; then
			print "debian_upgrade_local"
			debian_upgrade_local
		else
			print "I don't know what can I do for this type of machine"
		fi
  	elif [[ $1 = "help" || $1 = "--help" || $1 = "-h" ]] ; then
		print "local usage for upgrading Mac OS X or debian systems including fink and macports: upgrade and clean"
		print 'remote usage: upgrade $debian_server'
  	elif [ $1 ]; then
		for each in $argv
			upgrade_remote $each
	fi
	umask $UMASK_RESTORE
}
upgrade_remote () {
	print "remote upgrade"
	if [[ `ssh $each uname -o 2&>/dev/null` = "GNU/Linux" ]] ; then
		print "debian_upgrade_remote"
		debian_upgrade_remote $1
	elif [[ `ssh $each uname 2&>/dev/null` = "Darwin" ]] ; then
		print "osx_upgrade_remote"
		osx_upgrade_remote $1
	else
		print "$1 is not a debian nor an osx machine"
		print "please implement an upgrade function for this kind of machine!"
	fi
}
# update osx
update_osx () {
	local OSX_UP
	until [[ $OSX_UP == 'y' || $OSX_UP == 'n' ]]; do
		print -n "Process osx upgrade (y/n)?"
		read -q OSX_UP
	done;
	if [[ $OSX_UP == "y" ]] ; then
		print "=== update Mac systems ==="
		sudo softwareupdate -i -a
		if [ -x /usr/bin/gem ] ; then
			#sudo /usr/bin/gem update
			sudo env JAVA_HOME=$JAVA_HOME /usr/bin/gem update
		fi
	fi
}
# update fink packages
update_fink () {
	local FINK_UP
	until [[ $FINK_UP == 'y' || $FINK_UP == 'n' ]]; do
		print -n "Process fink upgrade (y/n)?"
		read -q FINK_UP
	done;
    if [[ $FINK_UP == "y" ]] ; then
		print "=== fink upgrade ==="
		sudo fink selfupdate
		sudo fink update-all
		sudo fink cleanup
		if [ -x /sw/bin/gem ] ; then # FIXME: path dependent
			#sudo /sw/bin/gem update
			sudo env JAVA_HOME=$JAVA_HOME /sw/bin/gem update
		fi
	fi
}
# update macports packages
update_macports () {
	local MACPORTS_UP
	until [[ $MACPORTS_UP == 'y' || $MACPORTS_UP == 'n' ]]; do
		print -n "Process macports upgrade (y/n)?"
		read -q MACPORTS_UP
	done;
	if [[ $MACPORTS_UP == "y" ]] ; then
		print "=== macports ==="
		#sudo port sync
		sudo port selfupdate
		sudo port upgrade outdated
		#sudo port clean installed
		if [ -x /opt/local/bin/gem ] ; then # FIXME: path dependent
			#sudo /opt/local/bin/gem update
			sudo env JAVA_HOME=$JAVA_HOME /opt/local/bin/gem update
		fi
	fi
}
# update textmate bundles
update_textmate () {
	local TEXTMATE_UP
	until [[ $TEXTMATE_UP == 'y' || $TEXTMATE_UP == 'n' ]]; do
		print -n "Process textmate update bundles (y/n)?"
		read -q TEXTMATE_UP
	done;
	if [[ $TEXTMATE_UP == "y" ]] ; then
		print "=== update textmate bundles ==="
		# global Textmate Bundles
		if [ -d /Library/Application\ Support/TextMate/Bundles ]; then
			pushd /Library/Application\ Support/TextMate/Bundles
			svn up *.tmbundle
			popd
			osascript -e 'tell app "TextMate" to reload bundles'		
		fi
		# local user Textmate Bundles
		if [ -d ~/Library/Application\ Support/TextMate/Bundles ]; then
			pushd ~/Library/Application\ Support/TextMate/Bundles
			svn up *.tmbundle
			popd
			osascript -e 'tell app "TextMate" to reload bundles'		
		fi
	fi
}
# refresh GPG keys
update_gpgkeys () {
	local GPG_UP
	until [[ $GPG_UP == 'y' || $GPG_UP == 'n' ]]; do
		print -n "Process GPG refresh-keys (y/n)?"
		read -q GPG_UP
	done;
	if [[ $GPG_UP == "y" ]] ; then
		print "=== gpg --refresh-keys ==="
   		gpg --refresh-keys	
	fi
}
# osx local upgrade 
osx_upgrade_local () {
	if test -x `which softwareupdate`; then
		update_osx
	fi
	if test -x `which fink`; then
		update_fink
	fi
	if test -x `which port`; then
		update_macports
	fi
	# mate is an alias, so `which mate` is not an executable
	if test -x /usr/local/bin/mate; then
		update_textmate
	fi
	if test -x `which gpg`; then
		update_gpgkeys
	fi
}
# local debian upgrade
debian_upgrade_local (){
	print "Upgrading Debian"
	sudo apt-get update && sudo apt-get -u upgrade
	print "Cleaning up"
	sudo apt-get clean
}
# remote osx upgrade
osx_upgrade_remote (){
	if [ ! $1 ]; then
		print "usage: osx_upgrade_remote $osx_server"
		print "Perhaps you want osx_upgrade_local ?"
	else
		# local variables declaration
	    local OSX_UP
	    local FINK_UP
	    local MACPORTS_UP
	    # ask before the upgrade
		until [[ $OSX_UP == 'y' || $OSX_UP == 'n' ]]; do
	    	print -n "Process osx upgrade on $1 (y/n)?"
	    	read -q OSX_UP
		done;
		until [[ $FINK_UP == 'y' || $FINK_UP == 'n' ]]; do
	    	print -n "Process fink upgrade on $1 (y/n)?"
	    	read -q FINK_UP
		done;
		until [[ $MACPORTS_UP == 'y' || $MACPORTS_UP == 'n' ]]; do
	    	print -n "Process macports upgrade on $1 (y/n)?"
	    	read -q MACPORTS_UP
		done;
		# upgrade if answer is y
	    if [[ $OSX_UP == "y" ]] ; then
			print "=== update Mac systems ==="
			ssh $1 -t /usr/bin/sudo /usr/sbin/softwareupdate -i -a
	    fi
	    if [[ $FINK_UP == "y" ]] ; then
			print "=== fink upgrade ==="
      		ssh $1 -t /usr/bin/sudo /sw/bin/fink selfupdate 
			ssh $1 -t /usr/bin/sudo /sw/bin/fink update-all 
			ssh $1 -t /usr/bin/sudo /sw/bin/fink cleanup
	    fi
	    if [[ $MACPORTS_UP == "y" ]] ; then
			print "=== macports ==="
      		ssh $1 -t /usr/bin/sudo /opt/local/bin/port selfupdate 
			#ssh $1 -t /usr/bin/sudo /opt/local/bin/port -uR upgrade outdated
			ssh $1 -t /usr/bin/sudo /opt/local/bin/port upgrade outdated
			ssh $1 -t /usr/bin/sudo /opt/local/bin/port clean installed
    	fi
  	fi
}
# remote debian upgrade
debian_upgrade_remote (){
	if [ ! $1 ]; then
		print "usage: debian_upgrade_remote $debian_server"
		print "Perhaps you want debian_upgrade_local ?"
	else
		print "remote debian upgrade on $1"
    ssh $1 -t sudo apt-get update
		# print what should be upgraded
    ssh $1 -t "sudo apt-get -s upgrade"
    # ask before the upgrade
    local dummy
    print -n "Process the upgrade y/n ?"
    read -q dummy
    if [[ $dummy == "y" ]] ; then
      ssh $1 -t "sudo apt-get -u upgrade --yes && \
								sudo apt-get clean && \
								sudo /usr/bin/gem update"
		fi
		print "upgrade on $1 done"
  fi
}
