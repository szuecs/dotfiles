import "foo"

node base {
  include common
}

node "www.foo.com" inherits base {
  include bar
}
