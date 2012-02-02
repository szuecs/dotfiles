import gdb

class _LPrintfBreakpoint(gdb.Breakpoint):
    def __init__(self, spec, command):
        super(_LPrintfBreakpoint, self).__init__(spec, gdb.BP_BREAKPOINT,
                                                 internal = False)
        self.command = command

    def stop(self):
        gdb.execute(self.command)
        return False

class _LPrintfCommand(gdb.Command):
    """Log some expressions at a location, using 'printf'.
    Usage: lprintf LINESPEC, FORMAT [, ARG]...
    Insert a breakpoint at the location given by LINESPEC.
    When the breakpoint is hit, do not stop, but instead pass
    the remaining arguments to 'printf' and continue.
    This can be used to easily add dynamic logging to a program
    without interfering with normal debugger operation."""

    def __init__(self):
        super(_LPrintfCommand, self).__init__('lprintf',
                                              gdb.COMMAND_DATA,
                                              # Not really the correct
                                              # completer, but ok-ish.
                                              gdb.COMPLETE_SYMBOL)

    def invoke(self, arg, from_tty):
        (remaining, locations) = gdb.decode_line(arg)
        if remaining is None:
            raise gdb.GdbError('printf format missing')
        remaining = remaining.strip(',')
        if locations is None:
            raise gdb.GdbError('no matching locations found')

        spec = arg[0:- len(remaining)]
        _LPrintfBreakpoint(spec, 'printf ' + remaining)

_LPrintfCommand()
print "lprintf loaded"
