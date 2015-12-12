NAME=fixed_fastica_loop_pipelined
ifeq (&(NO_OPT),)
	NO_OPT=1
endif
ifeq (&(NO_INLINE),)
	NO_INLINE=1
endif
LEVEL = /opt/legup/legup-4.0/examples
include $(LEVEL)/Makefile.common

LOCAL_CONFIG = -legup-config=config.tcl 

CFLAG += -mllvm -unroll-threshold=0
