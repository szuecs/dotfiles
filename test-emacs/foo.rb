#! /usr/bin/ruby -w

class Foo
  def foo
    "foo"
  end    
  
  def bar(*a)
    puts( a.join ", ")
  end
  def baz
  end
end

Foo.new.bar(1,2,3)

