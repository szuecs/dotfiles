# go-lang
case $(uname) in
"Darwin")
  # install pkg from https://golang.org/dl/
  export GOROOT=/usr/local/go
  export GOPATH=$HOME/go
  export GOBIN=$GOPATH/bin
  #export GOBIN=/usr/local/go/bin
  export GOOS=darwin
  export GOARCH=amd64
  ;;
esac
