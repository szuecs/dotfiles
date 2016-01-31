# test
require 'irb/completion'

#------------------------------------------------------------
# sync texteditor (vim,emacs,mate,..) with irb
# http://github.com/jberkel/interactive_editor 
#   > mate 
#   # edit.. , save, quit
#   > # use your written class, whatever within irb
begin
  require 'interactive_editor'
rescue Exception 
  puts "no interactive_editor available"
end
#------------------------------------------------------------
# http://sketches.rubyforge.org/
# save/reload an editor sketch from irb
#   > sketch :foo
begin
  require 'sketches'
  Sketches.config :editor => 'emacsclient -c'
rescue Exception 
  puts "no sketches available"
end
#------------------------------------------------------------
# hirb - rails nice ascii table formatter
# sucks terminal colors 
#begin 
#  require 'hirb' 
#  require 'hirb/import_object'
#  Hirb.enable
#  extend Hirb::Console
#rescue #drop
#end

#------------------------------------------------------------
# 
begin
  require 'looksee' 
  # print short help
  # irb> Looksee.help
  #
  # Looksee color config
  Looksee::styles[:module]     = "\e[0;47m%s\e[0m" # black on gray
  Looksee::styles[:public]     = "\e[0;32m%s\e[0m" # green
  Looksee::styles[:protected]  = "\e[0;33m%s\e[0m" # yellow
  Looksee::styles[:private]    = "\e[0;31m%s\e[0m" # red
  Looksee::styles[:undefined]  = "\e[0;34m%s\e[0m" # blue
  Looksee::styles[:overridden] = "\e[0;30m%s\e[0m" # black
  #Looksee.editor = "emacs -nw +%f %l"
  # yeah monkey patch for my emacsclient alias :)
  class InteractiveEditor
    module Editors
      {
        :vi    => nil,
        :vim   => nil,
        :emacs => nil,
        :e     => "emacsclient -c",
        :nano  => nil,
        :mate  => 'mate -w',
        :mvim  => 'mvim -g -f' + case ENV['TERM_PROGRAM']
          when 'iTerm.app';      ' -c "au VimLeave * !open -a iTerm"'
          when 'Apple_Terminal'; ' -c "au VimLeave * !open -a Terminal"'
          else '' #don't do tricky things if we don't know the Term
        end
      }.each do |k,v|
        define_method(k) do |*args|
          InteractiveEditor.edit(v || k, self, *args)
        end
      end
  
      def ed(*args)
        if ENV['EDITOR'].to_s.size > 0
          InteractiveEditor.edit(ENV['EDITOR'], self, *args)
        else
          raise "You need to set the EDITOR environment variable first"
        end
      end
    end
  end

  Looksee.editor = "e -nw +%f %l"
rescue Exception 
  puts "no looksee available"
end

#------------------------------------------------------------ 
# 
# global namespace polution
#

# got from http://ruby-doc.org/docs/ProgrammingRuby/html/ospace.html
def hierarchy klass
  if klass.instance_of? Class
    begin
      print klass
      klass = klass.superclass
      print " < " if klass
    end while klass
    puts
  end
end

# show_regexp - stolen from the pickaxe
def show_regexp(a, re)
   if a =~ re
      "#{$`}<<#{$&}>>#{$'}"
   else
      "no match"
   end
end

# a smarter RI
def ri arg
  @store ||= {}
  unless @store[arg]
    @store[arg] = `ri #{arg}`
  end
  puts @store[arg]
end

# print the last n commands from history
def last_cmds(n=1)
  puts Readline::HISTORY.entries[-(n+1)..-2].join("\n")
end

#   less { yp IRB.conf }
#def less
#  require 'stringio'
#  $stdout, sout = StringIO.new, $stdout
#  yield
#  $stdout, str_io = sout, $stdout
#   IO.popen('less', 'w') do |f|
#     f.write str_io.string
#     f.flush
#     f.close_write
#   end
#end

def yp(*data)
  require 'yaml'
  puts YAML::dump(*data)
end


#------------------------------------------------------------
# monkey patches

# Convenience method on Regexp so you can do
# /an/.show_match("banana")
class Regexp
   def show_match(a)
       show_regexp(a, self)
   end
end

#class Module
#  def ri(meth=nil)
#    if meth
#      if instance_methods(false).include? meth.to_s
#        puts `ri #{self}##{meth}`
#      else
#        super
#      end
#    else
#      puts `ri #{self}`
#    end
#  end
#end

# got from bkudria@github.com
# local_methods shows methods that are only available for a given object.
class Object
    # Return a list of methods defined locally for a particular object. Useful
    # for seeing what it does whilst losing all the guff that's implemented
    # by its parents (eg Object).
    def local_methods(obj = self)
        obj.methods(false).sort
    end
end

require 'cgi'
class String
  def to_base64
    [self].pack('m')
  end
  def from_base64
    self.unpack('m')
  end
  def unescape
    CGI.unescape self
  end
  def escape
    CGI.escape self
  end
end

#------------------------------------------------------------
# awesome_print : http://github.com/michaeldv/awesome_print
# 
# > data = [ false, 42, %w(forty two), { :now => Time.now, :class => Time}]
# > ap data
#
#require 'ap'
# use ap as default formatter
#IRB::Irb.class_eval do
#  def output_value
#    ap @context.last_value
#  end
#end

#------------------------------------------------------------
# irb config
IRB.conf[:USE_READLINE] = true
IRB.conf[:AUTO_INDENT]  = true
IRB.conf[:PROMPT][:CUSTOM] = {
  :PROMPT_N => "%N:%i> ",
  :PROMPT_S => "%N:%i%l ",
  :PROMPT_C => "%N:%i* ",
  :RETURN   =>  "=> %s\n",
  :PROMPT_I => "%N:%i> "
} 
IRB.conf[:PROMPT_MODE] = :CUSTOM # set default
#------------------------------------------------------------
# history
require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:EVAL_HISTORY] = 100

HISTFILE = "~/.irb.hist"
MAXHISTSIZE = 100

# restore history
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

# print an array like a tree
#   [1,2,[11,22,[111,222,333,444],33],3,4].recursive_print
class Object
 def recursive_print indent = ""
    puts indent.gsub(/\s+$/,"--") + to_s
  end
end
module Enumerable
  def recursive_print indent = ""
    map { |child| child.recursive_print indent+"|  " }
  end
end
