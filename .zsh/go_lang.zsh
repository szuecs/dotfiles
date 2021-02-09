# go-lang

export GO111MODULE=on

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
  # enable coredumps on crash or  Ctrl+backslash
  export GOTRACEBACK=crash
  ;;
esac

#function update_golang_tools () {
#	pushd
#	pushd ~/go/src/golang.org/x; for d in *; do cd $d; git co master; git pull --rebase; cd ..; done; popd
#	cd $GOPATH/src/golang.org/x/text ; GO111MODULE=on go get -u golang.org/x/text/...
#	cd $GOPATH/src/golang.org/x/tools ; GO111MODULE=on go get -u golang.org/x/tools/...
#	GO111MODULE=on go get -u golang.org/x/lint/golint
#	cd $GOPATH/src/github.com/google/gops; GO111MODULE=on go get -u github.com/google/gops/...
#	cd $GOPATH/src/github.com/cweill/gotests ; GO111MODULE=on go get -u github.com/cweill/gotests/...
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/uber/go-torch
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/rogpeppe/godef # go-guru can do jump to definition
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/mdempsky/gocode # new TODO replace and test
#	cd $GOPATH/src/github.com/golangci/golangci-lint ; GO111MODULE=on go get -u github.com/golangci/golangci-lint/...
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/remyoudompheng/go-misc/deadcode
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/kisielk/errcheck
#	cd $GOPATH/src/honnef.co/go/tools ; GO111MODULE=on go get -u honnef.co/go/tools/...
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/gordonklaus/ineffassign
#	cd $GOPATH/src/gitlab.com/opennota/check ; GO111MODULE=on go get -u gitlab.com/opennota/check/...
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/securego/gosec
#	cd $GOPATH/src ; GO111MODULE=on go install github.com/securego/gosec/cmd/gosec
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/davecheney/httpstat
#	cd $GOPATH/src ; GO111MODULE=on go get -u github.com/jgrahamc/httpdiff
#	cd $GOPATH/src/github.com/gohugoio/hugo ; GO111MODULE=on go get -u github.com/gohugoio/hugo
#	cd $GOPATH/src/github.com/derekparker/delve ; GO111MODULE=on go get -u github.com/derekparker/delve/cmd/dlv
#	pushd ~/go/src/github.com/golangci/golangci-lint; git pull --rebase; make test; mv golangci-lint $GOBIN/; popd
#	popd
#}
