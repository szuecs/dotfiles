require "minitest/unit"
require "mocha"

require "example"

MiniTest::Unit.autorun

class TestExample < MiniTest::Unit::TestCase
  include NameSpace
  
  def test_bar
    mc = MainClass.new(:parameter => "foo")
    mc.expects(:a_mocked_method).returns("return value")
    
    assert_equal('TEST', mc.bar_which_use_a_mocked_method)
  end
  
end
