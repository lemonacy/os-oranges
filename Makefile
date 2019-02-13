########################################
#       Makefile for Orange'S          #
########################################

# Entry point of Orange'S
# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT 			= 0x30400

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET 		= 0x400

# Programs, flags, etc.
ASM 				= nasm
DASM 				= ndisasm
CC 					= i386-elf-gcc
LD 					= i386-elf-ld
ASMBFLAGS 			= -I boot/include/
ASMKFLAGS 			= -I include/ -f elf
CFLAGS 				= -I include/ -c -fno-builtin
LDFLAGS 			= -s -Ttext $(ENTRYPOINT)
DASMFLAGS 			= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# This Program
ORANGESBOOT 		= boot/boot.bin boot/loader.bin
ORANGESKERNEL 		= kernel.bin
OBJS 				= kernel/global.o kernel/kernel.o kernel/start.o kernel/i8259.o kernel/protect.o lib/kliba.o lib/string.o lib/klib.o
DASMOUTPUT 			= kernel.bin.asm

# All Phony Targets
# .PHONY是一个伪指令，可以防止在Makefile中定义的命令名称和工作目录下的相同文件名出现名字冲突。
# 好比如果当前目录下有一个image文件，那么make image将不会执行下面的image指令
.PHONY : everything final image clean realclean disasm all buildimg

# Default starting position
everything : $(ORANGESBOOT) $(ORANGESKERNEL)

all : realclean everything

final : all clean

image : final buildimg

clean :
	rm -f $(OBJS)

realclean :
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

disasm:
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)

# We assume that 'a.img' exists in current folder
buildimg:
	dd if=boot/boot.bin of=a.img bs=512 count=1 conv=notrunc
	hdiutil mount a.img 						# macOS上挂载
	cp -fv boot/loader.bin /Volumes/Untitled/
	cp -fv kernel.bin /Volumes/Untitled/
	hdiutil unmount /Volumes/Untitled/			# macOS上卸载

boot/boot.bin : boot/boot.asm boot/include/load.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/load.inc boot/include/fat12hdr.inc boot/include/pm.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

$(ORANGESKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $(ORANGESKERNEL) $(OBJS)

kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/global.o: kernel/global.c include/global.h include/const.h include/type.h include/protect.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/type.h include/const.h include/protect.h include/type.h include/proto.h include/const.h include/string.h include/global.h include/protect.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/i8259.o: kernel/i8259.c include/const.h include/protect.h include/type.h include/proto.h include/const.h
	$(CC) $(CFLAGS) -o $@ $<

kernel/protect.o: kernel/protect.c include/const.h include/global.h include/const.h include/type.h include/protect.h include/proto.h include/type.h
	$(CC) $(CFLAGS) -o $@ $<

lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/klib.o : lib/klib.c
	$(CC) $(CFLAGS) -o $@ $<
