#
# Be silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
Q		:= @
NULL		:= 2>/dev/null
endif

SRC_DIR        = src
INC_DIR        = inc
OPENCM3_DIR    = libopencm3
BIN_DIR = bin

BINARY = main

LIBNAME			= opencm3_stm32f4
DEFS				+= -DSTM32F4
FP_FLAGS		?= -mfloat-abi=hard -mfpu=fpv4-sp-d16
ARCH_FLAGS	= -mthumb --target=arm-none-eabi -mcpu=cortex-m4 $(FP_FLAGS)


LDSCRIPT = linkerscript.ld
LDLIBS		+= -l$(LIBNAME)
LDFLAGS		+= -L$(OPENCM3_DIR)/lib

DEFS		+= -I$(OPENCM3_DIR)/include

CC		:= clang 
LD		:= clang
AR		:= llvm-ar
AS		:= llvm-as
OBJCOPY		:= llvm-objcopy
OBJDUMP		:= llvm-objdump
GDB		:= lldb
STFLASH		= $(shell which st-flash)
OPT		:= -Os
DEBUG		:= -ggdb3
CSTD		?= -std=c99


SRC  = $(wildcard src/**/*.c) $(wildcard src/*.c) $(wildcard src/**/**/*.c) $(wildcard src/**/**/**/*.c)
OBJS  = $(SRC:.c=.o)


TGT_CFLAGS	+= -MD
#TGT_CFLAGS	+= --target=arm-none-eabi
TGT_CFLAGS	+= $(OPT) $(CSTD) $(DEBUG)
TGT_CFLAGS	+= $(ARCH_FLAGS)
TGT_CFLAGS	+= -Wextra -Wshadow -Wimplicit-function-declaration
TGT_CFLAGS	+= -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes
TGT_CFLAGS	+= -fno-common -ffunction-sections -fdata-sections
TGT_CFLAGS 	+= $(DEFS)

TGT_LDFLAGS		+= -nostdlib
TGT_LDFLAGS		+= -T$(LDSCRIPT)
TGT_LDFLAGS		+= $(ARCH_FLAGS) $(DEBUG)
TGT_LDFLAGS		+= -Wl,-Map=$(*).map -Wl,--cref
TGT_LDFLAGS		+= -Wl,--gc-sections
ifeq ($(V),99)
TGT_LDFLAGS		+= -Wl,--print-gc-sections
endif


LDLIBS		+= -Wl,--start-group -Wl,--end-group


.SUFFIXES: .elf .bin .hex .srec .list .map .images
.SECONDEXPANSION:
.SECONDARY:

all: elf bin

elf: $(BINARY).elf
bin: $(BINARY).bin
hex: $(BINARY).hex
srec: $(BINARY).srec
list: $(BINARY).list
GENERATED_BINARIES=$(BINARY).elf $(BINARY).bin $(BINARY).hex $(BINARY).srec $(BINARY).list $(BINARY).map

images: $(BINARY).images
flash: $(BINARY).flash

$(OPENCM3_DIR)/lib/lib$(LIBNAME).a:
ifeq (,$(wildcard $@))
	$(warning $(LIBNAME).a not found, attempting to rebuild in $(OPENCM3_DIR))
	$(MAKE) -C $(OPENCM3_DIR)
endif

print-%:
	@echo $*=$($*)

%.o: %.c
	$(CC) -o $@ -c $< $(CFLAGS)

%.images: %.bin %.hex %.srec %.list %.map
	@#printf "*** $* images generated ***\n"

%.bin: %.elf
	@#printf "  OBJCOPY $(*).bin\n"
	$(Q)$(OBJCOPY) -Obinary $(*).elf $(*).bin

%.hex: %.elf
	@#printf "  OBJCOPY $(*).hex\n"
	$(Q)$(OBJCOPY) -Oihex $(*).elf $(*).hex

%.srec: %.elf
	@#printf "  OBJCOPY $(*).srec\n"
	$(Q)$(OBJCOPY) -Osrec $(*).elf $(*).srec

%.list: %.elf
	@#printf "  OBJDUMP $(*).list\n"
	$(Q)$(OBJDUMP) -S $(*).elf > $(*).list

%.elf %.map: $(OBJS) $(LDSCRIPT) $(OPENCM3_DIR)/lib/lib$(LIBNAME).a Makefile
	@#printf "  LD      $(*).elf\n"
	$(Q)$(LD) $(TGT_LDFLAGS) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $(*).elf

%.o: %.c
	@#printf "  CC      $(*).c\n"
	$(Q)$(CC) $(TGT_CFLAGS) $(CFLAGS) -o $(*).o -c $(*).c

%.o: %.S
	@#printf "  CC      $(*).S\n"
	$(Q)$(CC) $(TGT_CFLAGS) $(CFLAGS) -o $(*).o -c $(*).S

clean:
	@#printf "  CLEAN\n"
	$(Q)$(RM) $(GENERATED_BINARIES) generated.* $(OBJS) $(OBJS:%.o=%.d)


.PHONY: images clean elf bin hex srec list

-include $(OBJS:.o=.d)
