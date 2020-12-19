#
# Spécifique au Projet
# LIB

CC65PATH = ../../cc65/bin
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

AS = $(CC65PATH)/ca65
LD = $(CC65PATH)/ld65
AR = $(CC65PATH)/ar65

#
# Définition des options pour les outils
#

ifeq ($(DEBUG),yes)
	ASFLAGS = -t telestrat -I $(BUILDPATH) -I $(SDK_PATH) -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE) -D DEBUG --list-bytes 0 -l $(BUILDPATH)/$(PROJECT).lst --debug-info
	LDFLAGS = -t telestrat -Ln $(BUILDPATH)/$(PROJECT).ca.sym -m $(BUILDPATH)/$(PROJECT).map
	ARFLAGS =
else
	ASFLAGS = -t telestrat -I $(BUILDPATH) -I $(SDK_PATH) -I $(SHELL_PATH) -I $(KERNEL_PATH) -D VERBOSE_LEVEL=$(VERBOSE)
	LDFLAGS = -t telestrat
	ARFLAGS = v
endif


#
# Règles Make
#

SRC = $(wildcard *.s)
OBJS= $(addprefix $(BUILDPATH)/, $(patsubst %.s,%.o, $(SRC)))
LIB = $(PROJECT).lib

all: $(BUILDPATH)/$(LIB)


$(BUILDPATH)/%.o: %.s
	@echo "AS target: $@ member: $% 1st prereq: $< stem: $*"
	@echo "  newer: $? all prereq: $^"
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILDPATH)/$(LIB): $(OBJS)
	@echo "build lib target: $@ member: $% 1st prereq: $< stem: $*"
	@echo "  newer: $? all prereq: $^"
	$(AR) $(ARFLAGS) r $@ $?

configure:
	@echo "Create $(BUILDPATH)/build.inc file"
	@mkdir -p $(BUILDPATH)
	@#date +'.define __DATE__ "__DATE__"'           > $(BUILDPATH)/build.inc
	@date +'.define __DATE__ "%F %R"'               > $(BUILDPATH)/build.inc
	@echo  ".define __VERSION__ \"${VERSION}\""     >> $(BUILDPATH)/build.inc


.PHONY: clean mrproper


clean:
	cd $(BUILDPATH) && rm -f *.o


mrproper: clean
	cd $(BUILDPATH) && rm -f $(LIB) *.lst *.sym .depend build.inc
