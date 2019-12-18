#
# Copyright (C) 2019 Chris McClelland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright  notice and this permission notice  shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# Launch ModelSim in GUI mode, with appropriate window layout
proc gui_run {ncw vcw go gp start width cursor} {
    add wave -div ""
    configure wave -namecolwidth $ncw
    configure wave -valuecolwidth $vcw
    configure wave -gridoffset "${go}ns"
    configure wave -gridperiod "${gp}ns"
    onbreak resume
    run -all
    view wave
    set end [expr ${start}+${gp}*${width}]
    bookmark add wave default "${start}ns ${end}ns"
    bookmark goto wave default
    wave activecursor 1
    wave cursortime -time "${cursor}ns"
    wave refresh
}

proc vsim_run {tb} {
    if {$::env(VOPT) == "0"} {
        echo "Running without vopt by default: put VOPT := 1 in your Makefile to enable it"
        eval "vsim -novopt -t ps $::env(DEF_LIST) -L work_lib $::env(LIB_LIST) ${tb}"
    } elseif {[string match "*ModelSim ALTERA*" [vsim -version]]} {
        echo "Running without vopt because ModelSim Altera does not support it"
        eval "vsim -novopt -t ps $::env(DEF_LIST) -L work_lib $::env(LIB_LIST) ${tb}"
    } else {
        echo "Running with vopt..."
        eval "vopt +acc ${tb} -o ${tb}_opt $::env(DEF_LIST) -L work_lib $::env(LIB_LIST)"
        eval "vsim -t ps ${tb}_opt"
    }
}

proc cli_run {} {
    foreach tb [split $::env(TESTBENCH) " "] {
        vsim_run ${tb}
        run -all
    }
    exit -force -code [coverage attribute -name TESTSTATUS -concise]
}
