
ARMGNU?=arm-none-eabi

COPS = -Wall  -Os -nostdlib -nostartfiles -ffreestanding -save-temps
AOPS = --warn --fatal-warnings

all : mecrisp-stellaris-stm32g031j6.bin 

mecrisp-stellaris-stm32g031j6.o : mecrisp-stellaris-stm32g031j6.s
	$(ARMGNU)-as mecrisp-stellaris-stm32g031j6.s -o mecrisp-stellaris-stm32g031j6.o

mecrisp-stellaris-stm32g031j6.bin : memmap mecrisp-stellaris-stm32g031j6.o
	$(ARMGNU)-ld -o mecrisp-stellaris-stm32g031j6.elf -T memmap mecrisp-stellaris-stm32g031j6.o
	$(ARMGNU)-objdump -D mecrisp-stellaris-stm32g031j6.elf > mecrisp-stellaris-stm32g031j6.list
	$(ARMGNU)-objcopy mecrisp-stellaris-stm32g031j6.elf mecrisp-stellaris-stm32g031j6.bin -O binary

clean:
	rm -f *.bin
	rm -f *.o
	rm -f *.elf
	rm -f *.list
