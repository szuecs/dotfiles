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

# rr - https://github.com/mozilla/rr/wiki/Using-rr-in-an-IDE
# enable ptrace:
#   % echo -1 | sudo tee -a /proc/sys/kernel/perf_event_paranoid
#   % echo 0 | sudo tee -a /proc/sys/kernel/kptr_restrict
#
# get around CLion/QtCreator not supporting target extended-remote
define target remote
target extended-remote $arg0
end
define target hook-extended-remote
source ~/.rr_gdbinit
end
# optional: prevent gdb asking for confirmation
# when invoking the run command in gdb
set confirm off
set remotetimeout 100000

# go warning when using gcore to get coredump
set auto-load safe-path /
#set auto-load safe-path /usr/share/go1.12.7/src/runtime/runtime-gdb.py
# add-auto-load-safe-path /usr/share/go1.12.7/src/runtime/runtime-gdb.py

