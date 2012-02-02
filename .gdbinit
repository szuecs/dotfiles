# fail fast (off|soft|strict)
set script-extension strict
source ~/.gdb.d/conf

# dynamic load if you need
define session-ruby
  source ~/.gdb.d/ruby
end
define session-asm
  source ~/.gdb.d/asm
  source ~/.gdb.d/hex_ascii_commands
end
define session-fscript
  source ~/.gdb.d/FScript_injector
end
define session-python
  source ~/.gdb.d/python/lprintf.py
end

source ~/.gdb.d/process_context_commands
source ~/.gdb.d/breakpoint_aliase
source ~/.gdb.d/process_info
source ~/.gdb.d/process_info_commands

