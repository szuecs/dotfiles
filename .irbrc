require 'rubygems'
require 'irb/completion'

# show_regexp - stolen from the pickaxe
def show_regexp(a, re)
   if a =~ re
      "#{$`}<<#{$&}>>#{$'}"
   else
      "no match"
   end
end

# Convenience method on Regexp so you can do
# /an/.show_match("banana")
class Regexp
   def show_match(a)
       show_regexp(a, self)
   end
end

IRB.conf[:USE_READLINE] = true
IRB.conf[:AUTO_INDENT]  = true

# Prompts
# classic style:
#IRB.conf[:PROMPT][:CUSTOM] = {
#  :PROMPT_N => "%N(%m):%03n:%i> ",
#  :PROMPT_S => "%N(%m):%03n:%i%l ",
#  :PROMPT_C => "%N(%m):%03n:%i* ",
#  :RETURN   =>  "=> %s\n",
#  :PROMPT_I => "%N(%m):%03n:%i> "
#}
IRB.conf[:PROMPT][:CUSTOM] = {
  :PROMPT_N => "%N:%i> ",
  :PROMPT_S => "%N:%i%l ",
  :PROMPT_C => "%N:%i* ",
  :RETURN   =>  "=> %s\n",
  :PROMPT_I => "%N:%i> "
}
IRB.conf[:PROMPT_MODE] = :CUSTOM # set default

#### This for history (I believe I got it from Rubygarden):

require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:EVAL_HISTORY] = 100

HISTFILE = "~/.irb.hist"
MAXHISTSIZE = 100

begin
  if defined? Readline::HISTORY
    histfile = File::expand_path( HISTFILE )
    if File::exists?( histfile )
      lines = IO::readlines( histfile ).collect {|line| line.chomp}
      puts "Read %d saved history commands from %s." % 
        [ lines.nitems, histfile ] if $DEBUG || $VERBOSE 
        Readline::HISTORY.push( *lines )
    else
      puts "History file '%s' was empty or non-existant." % 
      histfile if $DEBUG || $VERBOSE
    end

    Kernel::at_exit {
      lines = Readline::HISTORY.to_a.reverse.uniq.reverse
      lines = lines[ -MAXHISTSIZE, MAXHISTSIZE ] if lines.size > MAXHISTSIZE
      $stderr.puts "Saving %d history lines to %s." %

      [ lines.length, histfile ] if $VERBOSE || $DEBUG
      File::open( histfile, File::WRONLY|File::CREAT|File::TRUNC ) do |ofh|
        lines.each {|line| ofh.puts line }
      end
    }
  end
end

#### And this for RI (again, from Rubygarden or someone's blog, I forget which):
def ri arg
  @last = `ri #{arg}`
   puts @last
end

class Module
  def ri(meth=nil)
    if meth
      if instance_methods(false).include? meth.to_s
        puts `ri #{self}##{meth}`
      else
        super
      end
    else
      puts `ri #{self}`
    end
  end
end

####   less { yp IRB.conf }
def less
  require 'stringio'
  $stdout, sout = StringIO.new, $stdout
  yield
  $stdout, str_io = sout, $stdout
   IO.popen('less', 'w') do |f|
     f.write str_io.string
     f.flush
     f.close_write
   end
end

def yp(*data)
  require 'yaml'
  puts YAML::dump(*data)
end