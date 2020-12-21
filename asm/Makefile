#
# Spécifique au Projet
# LIB

PROJECT = orix-sdk
BUILDPATH = ../build/lib

KERNEL_PATH = ../../orix-software/
SHELL_PATH = ../../orix-software/
SDK_PATH = ../

VERSION ?= "0.01"
VERBOSE ?= 0

# %<-------------------------------------------------------------------------->%
#               Ne rien modifier au dela de cette ligne
#

#
# Définition des outils
#

ifeq ($(CC65_HOME),)
	CC = cc65
	AS = ca65
	LD = ld65
	AR = ar65
else
	CC = $(CC65_HOME)/bin/cc65
	AS = $(CC65_HOME)/bin/ca65
	LD = $(CC65_HOME)/bin/ld65
	AR = $(CC65_HOME)/bin/ar65
endif

#
# Définition des options pour les outils
#

ifeq ($(DEBUG),yes)
	ASFLAGS = -t telestrat -I $(BUILD_PATH) -I $(SDK_PATH) -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) -D DEBUG --list-bytes 0 -l $(BUILD_PATH)/$(PROJECT).lst --debug-info
	LDFLAGS = -t telestrat -Ln $(BUILD_PATH)/$(PROJECT).ca.sym -m $(BUILD_PATH)/$(PROJECT).map
	ARFLAGS =
else
	ASFLAGS = -t telestrat -I $(BUILD_PATH) -I $(SDK_PATH) -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE)
	LDFLAGS = -t telestrat
	ARFLAGS = v
endif


#
# Règles Make
#

SRC = $(wildcard *.s)
OBJS= $(addprefix $(BUILD_PATH)/, $(patsubst %.s,%.o, $(SRC)))
LIB = $(PROJECT).lib

all: $(BUILD_PATH)/$(LIB)


$(BUILD_PATH)/%.o: %.s
	@echo "AS target: $@ member: $% 1st prereq: $< stem: $*"
	@echo "  newer: $? all prereq: $^"
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD_PATH)/$(LIB): $(OBJS)
	@echo "build lib target: $@ member: $% 1st prereq: $< stem: $*"
	@echo "  newer: $? all prereq: $^"
	$(AR) $(ARFLAGS) r $@ $?

configure:
	@echo "Create $(BUILD_PATH)/build.inc file"
	@mkdir -p $(BUILD_PATH)
	@#date +'.define __DATE__ "__DATE__"'           > $(BUILD_PATH)/build.inc
	@date +'.define __DATE__ "%F %R"'               > $(BUILD_PATH)/build.inc
	@echo  ".define __VERSION__ \"${VERSION}\""     >> $(BUILD_PATH)/build.inc


.PHONY: clean mrproper


clean:
	cd $(BUILD_PATH) && rm -f *.o


mrproper: clean
	cd $(BUILD_PATH) && rm -f $(LIB) *.lst *.sym .depend build.inc
