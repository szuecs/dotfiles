# go-lang
case $(uname) in
"Darwin")
  export GOROOT=/usr/local/go
  export GOPATH=$HOME/go
  export GOBIN=$GOPATH/bin
  export GOOS=darwin
  export GOARCH=amd64
  PATH=${PATH}:${GOROOT}/bin:${GOBIN}
  ;;
"Linux")
  # go binary packages
  #export GOROOT=/usr/lib/go
  export GOROOT=/usr/share/go
  export GOPATH=$HOME/go
  export GOBIN=$GOPATH/bin
  PATH=${PATH}:${GOROOT}/bin:${GOBIN}
  ;;
esac
