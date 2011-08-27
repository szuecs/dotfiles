require 'optparse'

module NameSpace
  VERSION = '10.11.1'
  
  class MainClass
    
    class << self
      def default_options
        {
          :parameter => "default_value",
        }
      end
      
      def parse_options
        options = default_options
        
        executable_name = File.basename(__FILE__).sub(/\.rb$/,'')
        
        OptionParser.new do |opts|
          opts.banner  = "% #{executable_name} [options]"
          opts.version = ::NameSpace::VERSION
          opts.separator ""
          opts.separator "Specific options:"
          opts.separator ""
          
          opts.on('-h', '--help', 'Display this help.') do
            abort "#{opts}"
          end
          opts.on('-V', '--version', 'Print version.') do |s|
            abort("#{executable_name} #{::NameSpace::VERSION}")
          end
          
          opts.on('--parameter <name>', 'example parameter.') do |s|
            options[:parameter] = s
          end
          
          begin
            opts.parse!
          rescue => e
            abort "#{e}\n\n#{opts}"
          end
        end
        options
      end
      
      def main(options)
        mc = NameSpace::MainClass.new(options)
        # do sth with mc..
        
        return 0
      end
    end # class methods end
    
    def initialize(options)
      @parameter = options[:parameter]
    end
    
    private
    
  end
end

