# go-lang
case $(uname) in
"Darwin") 
  local hombrew_dir=`brew --cellar go` 
  if [ -d $hombrew_dir ]; then
    export GOROOT=$hombrew_dir
    export GOBIN=/usr/local/bin
    export GOOS=darwin
    export GOARCH=amd64
  fi
  ;;
esac