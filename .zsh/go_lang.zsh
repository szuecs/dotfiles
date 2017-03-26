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
    PATH=${PATH}:${GOROOT}/bin:${GOBIN}
  else
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin
    export GOOS=darwin
    export GOARCH=amd64
    PATH=${PATH}:${GOROOT}/bin:${GOBIN}
  fi
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
