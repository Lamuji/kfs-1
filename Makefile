# Déclaration des variables
CC = /home/ramzi/cross-compiler/i686-elf/bin/i686-elf-gcc
AS = /home/ramzi/cross-compiler/i686-elf/bin/i686-elf-as
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra
LDFLAGS = -ffreestanding -O2 -nostdlib

# Nom du kernel
KERNEL = myos.bin

# Liste des fichiers objets
OBJS = boot.o kernel.o

# Règle par défaut
all: $(KERNEL) iso

# Règle pour compiler les fichiers .c en .o
%.o: %.c
	$(CC) -c $< -o $@ $(CFLAGS)

# Règle pour assembler les fichiers .s en .o
%.o: %.s
	$(AS) $< -o $@

# Règle pour lier les fichiers objets en un kernel
$(KERNEL): $(OBJS)
	$(CC) -T linker.ld -o $@ $(LDFLAGS) $(OBJS) -lgcc
	@echo "Kernel compilation terminée!"

# Règle pour vérifier que le kernel est bien multiboot
check: $(KERNEL)
	@if grub-file --is-x86-multiboot $(KERNEL); then \
		echo "Multiboot confirmé."; \
	else \
		echo "Le fichier n'est pas multiboot."; \
		exit 1; \
	fi

# Règle pour créer une image ISO bootable
iso: $(KERNEL) check
	@mkdir -p isodir/boot/grub
	@cp $(KERNEL) isodir/boot/$(KERNEL)
	@echo 'menuentry "42 Kernel" {\n\tmultiboot /boot/$(KERNEL)\n}' > isodir/boot/grub/grub.cfg
	@grub-mkrescue -o myos.iso isodir
	@echo "Image ISO créée!"

# Règle pour nettoyer le projet
clean:
	rm -f $(OBJS) $(KERNEL) myos.iso
	rm -rf isodir

# Règle pour tester le kernel avec QEMU
run: iso
	qemu-system-i386 -cdrom myos.iso

# Règle pour tester le kernel directement avec QEMU
run-kernel: $(KERNEL)
	qemu-system-i386 -kernel $(KERNEL)

.PHONY: all check iso clean run run-kernel