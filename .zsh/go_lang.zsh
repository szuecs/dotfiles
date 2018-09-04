# go-lang
case $(uname) in
"Darwin")
  local hombrew_dir=`brew --cellar go`
  if [ -d $hombrew_dir ]
  then
    export GOROOT=$hombrew_dir
    export GOBIN=/usr/local/bin
    export GOOS=darwin
    export GOARCH=amd64
    PATH=${GOROOT}/bin:${GOBIN}:${PATH}
  else
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin
    export GOOS=darwin
    export GOARCH=amd64
    PATH=${GOROOT}/bin:${GOBIN}:${PATH}
  fi
  ;;
"Linux")
  # go binary packages
  #export GOROOT=/usr/lib/go
  export GOROOT=/usr/share/go
  export GOPATH=$HOME/go
  export GOBIN=$GOPATH/bin
  PATH=${GOROOT}/bin:${GOBIN}:${PATH}
  ;;
esac

function update_golang_tools () {
	for repo in github.com/Masterminds/glide github.com/Masterminds/glide-report github.com/cpuguy83/go-md2man github.com/cweill/gotests github.com/davecheney/httpstat github.com/golang/lint github.com/google/gops github.com/jgrahamc/httpdiff github.com/monochromegane/the_platinum_searcher github.com/nsf/gocode github.com/rogpeppe/godef github.com/spf13/hugo github.com/uber/go-torch golang.org/x/text golang.org/x/tools
	do
		cd $GOPATH/src/$repo
		git co master
	done
	go get -u golang.org/x/text/...
	go get -u golang.org/x/tools/...
	go get -u github.com/golang/lint/...
	go get -u github.com/google/gops/...
	go get -u github.com/cweill/gotests/...
	go get -u github.com/uber/go-torch
	go get -u github.com/rogpeppe/godef
	go get -u github.com/nsf/gocode
	go get -u github.com/davecheney/httpstat
	go get -u github.com/jgrahamc/httpdiff
	go get -u github.com/cpuguy83/go-md2man
	go get -u github.com/Masterminds/glide
	go get -u github.com/Masterminds/glide-report
	go get -u github.com/spf13/hugo
	go get -u github.com/monochromegane/the_platinum_searcher
	go get -u github.com/monochromegane/the_platinum_searcher/...
	go get -u github.com/alecthomas/gometalinter
	gometalinter -iuf
}
