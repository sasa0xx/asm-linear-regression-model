ASM = nasm
ASFLAGS = -felf64
LD = gcc
LDFLAGS = -no-pie -nostdlib

SRCS = main.asm model.asm loss.asm puts.asm
OBJS = $(SRCS:.asm=.o)
TARGET = lr

.PHONY: all clean

all: $(TARGET)

%.o: %.asm
	$(ASM) $(ASFLAGS) $< -o $@

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
