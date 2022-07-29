ifndef CROSS_COMPILE
	#CROSS_COMPILE = mips-linux-gnu-
CROSS_COMPILE = mips-sde-elf-
endif
CC = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

OBJECT = inst_rom.o

all: inst_rom.data inst_rom.mif debug

%.o: %.s
	$(CC) -mips32 $< -o $@

inst_rom.om: ram.ld $(OBJECT)
	$(LD) -T ram.ld $(OBJECT) -o $@

inst_rom.bin: inst_rom.om
	$(OBJCOPY) -S -O binary -j .text $< $@

inst_rom.data: inst_rom.bin
	./bin2mem -o $@ $<

inst_rom.mif : inst_rom.data
	./txt2mif -o $@ $<

.PHONY: clean debug git
clean:
	rm -f *.o *.om *.bin *.data *.asm

debug:
	$(OBJDUMP) -D inst_rom.om > inst_rom.asm

git:
	#@git add .
	#@git commit -m "auto-commit: Update Program"
