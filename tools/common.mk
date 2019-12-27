BOLD := $(shell tput bold; tput setaf 4)
NORM := $(shell tput sgr0)
REALPATH := $(realpath .)
LIBNAME := $(notdir $(REALPATH))
DIRNAME := $(REALPATH:$(PROJ_HOME)%=\$$PROJ_HOME%)
GENERATE := .tgt/gen
COMPILE := .tgt/compile
LIBDIR_REL := ip/sim-libs
LIBDIR := $(PROJ_HOME)/$(LIBDIR_REL)
VOPT ?= 0
ifeq ($(DEBUG),1)
  ECHO := echo
else
  ECHO := \#echo
endif
export VOPT
export LIB_LIST := $(LIBS:%=-L %)
export DEF_LIST := $(DEFS:%=-g%)
INC_LIST := $(INCS:%=+incdir+%)

.PHONY: sub_gen gen compile test clean

# -- Test ------------------------------------------------------------------------------------------
ifeq ($(LIBNAME:tb-%=tb-),tb-)
  ifneq ($(SUBDIRS),)
    $(error $(BOLD)A test directory may not set SUBDIRS$(NORM))
  else ifneq ($(WORK),)
    $(error $(BOLD)A test directory may not set WORK$(NORM))
  endif
  ifeq ($(COVERAGE),1)
    VLOPTS += +cover
  endif
  WORKINFO := work/_info
  VLOG := vlog -nologo -sv -novopt -hazards -lint -pedanticerrors +define+SIMULATION $(VLOPTS) $(LIB_LIST) $(INC_LIST) +incdir+$(PROJ_HOME)/tools +incdir+$(PROJ_HOME)/tools/svunit
  VCOM := vcom -nologo -2008 -novopt $(VHOPTS)
  export TESTBENCH
  export CONTINUE_ON_FAILURE
  export COVERAGE

  gen:: $(GENERATE)
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"test\"/>"

  compile: gen modelsim.ini $(WORKINFO) $(COMPILE)
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"test\"/>"

  ifeq ($(shell test -f sim.do; echo $$?),0)
    test: compile
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"test\"/>"
	@echo "$(BOLD)Running tests in $(DIRNAME) using sim.do$(NORM)"
	@vsim -c -do 'source sim.do; do_test 0'
	@echo

    testgui: compile
	@vsim -do 'source sim.do; do_test 1'
  else
    test: compile
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"test\"/>"
	@echo "$(BOLD)Autorunning tests in $(DIRNAME)$(NORM)"
	@vsim -c -do 'source $(PROJ_HOME)/tools/common.do; cli_run; finish'
	@echo
  endif

  clean::
	rm -rf .tgt work modelsim.ini transcript fontconfig vsim.wlf coverage.txt

  $(COMPILE): $(PROJ_HOME)/tools/svunit/svunit_pkg.sv
  $(WORKINFO):
	@echo "$(BOLD)Preparing local work library for test directory $(DIRNAME)$(NORM)"
	vlib work
	vmap work_lib work
	@echo

  modelsim.ini:
	@echo "$(BOLD)Preparing local modelsim.ini for test directory $(DIRNAME)$(NORM)"
	cp -p $(LIBDIR)/modelsim.ini .
	@echo

# -- RTL -------------------------------------------------------------------------------------------
else ifdef WORK
  ifeq ($(COVERAGE),1)
    VLOPTS += +cover
  endif
  export MODELSIM := $(LIBDIR)/modelsim.ini
  WORKINFO := $(LIBDIR)/$(WORK)/_info
  VLOG := vlog -nologo -sv -novopt -hazards -lint -pedanticerrors +define+SIMULATION $(VLOPTS) $(LIB_LIST) $(INC_LIST) -work $(WORK)
  VCOM := vcom -nologo -93 -novopt -check_synthesis $(VHOPTS) $(LIB_LIST) -work $(WORK)

  gen:: sub_gen $(GENERATE)
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"rtl\" work=\"$(WORK)\" subdirs=\"$(SUBDIRS)\"/>"

  sub_gen:
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"rtl\" work=\"$(WORK)\" subdirs=\"$(SUBDIRS)\">"
	@(for DIR in $(SUBDIRS); do make -C $$DIR gen || exit; done)
	@$(ECHO) "EXEC: </$@>"

  compile: gen $(MODELSIM) $(WORKINFO) $(COMPILE)
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"rtl\" work=\"$(WORK)\" subdirs=\"$(SUBDIRS)\">"
	@(for DIR in $(SUBDIRS); do make -C $$DIR compile || exit; done)
	@$(ECHO) "EXEC: </$@>"

  test: compile
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"rtl\" work=\"$(WORK)\" subdirs=\"$(SUBDIRS)\">"
	@(for DIR in $(SUBDIRS); do make -C $$DIR test || exit; done)
	@$(ECHO) "EXEC: </$@>"

  clean::
	rm -rf .tgt

  $(WORKINFO):
	@echo "$(BOLD)Preparing shared library (work=\"$(WORK)\") for RTL directory $(DIRNAME)$(NORM)"
	vlib $(LIBDIR)/$(WORK)
	vmap $(WORK) \$$PROJ_HOME/$(LIBDIR_REL)/$(WORK)
	@echo

  $(MODELSIM):
	@echo "$(BOLD)Preparing shared \$$PROJ_HOME/$(LIBDIR_REL)/modelsim.ini file$(NORM)"
	@rm -rf $(dir $@)
	@mkdir $(dir $@)
	@rm -f modelsim.ini
	@unset MODELSIM && vmap -c
	@mv modelsim.ini $@
	@echo

# -- Hierarchy -------------------------------------------------------------------------------------
else
  ifeq ($(SUBDIRS),)
    $(error $(BOLD)A hierarchy directory must set SUBDIRS$(NORM))
  endif

  gen::
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"hierarchy\" subdirs=\"$(SUBDIRS)\">"
	@(for DIR in $(SUBDIRS); do make -C $$DIR gen || exit; done)
	@$(ECHO) "EXEC: </$@>"

  compile:
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"hierarchy\" subdirs=\"$(SUBDIRS)\">"
	@(for DIR in $(SUBDIRS); do make -C $$DIR compile || exit; done)
	@$(ECHO) "EXEC: </$@>"

  test:
	@$(ECHO) "EXEC: <$@ loc=\"$(DIRNAME)\" type=\"hierarchy\" subdirs=\"$(SUBDIRS)\">"
	@(for DIR in $(SUBDIRS); do make -C $$DIR test || exit; done)
	@$(ECHO) "EXEC: </$@>"
endif

clean::
	@for DIR in $(SUBDIRS); do make -C $$DIR clean; done

.tgt:
	@mkdir $@

$(GENERATE): | .tgt

$(COMPILE): $(GENERATE)

%/gen:
	@touch $@

%/compile:
	@(for i in $^; do \
	  if [ $${i##*.} = sv ]; then \
	    echo "$(BOLD)Compiling SystemVerilog file: $${i}$(NORM)"; \
	    echo "$(VLOG) $${i}"; \
	    $(VLOG) $${i} || exit; \
	    echo; \
	  elif [ $${i##*.} = vhdl ]; then \
	    echo "$(BOLD)Compiling VHDL file: $${i}$(NORM)"; \
	    $(VCOM) $${i} || exit; \
	    echo; \
	  fi \
	done)
	@touch $@

# TODO: Figure out how to fail a QuestaSim build (Questa doesn't generate the "Errors: 0" summaries)
#CHECK_MODELSIM := test "$$(cat transcript | perl -ane 'if(m/^\# Errors: (\d+),/g){print"$$1\n";}' | sort | uniq)" = "0"
