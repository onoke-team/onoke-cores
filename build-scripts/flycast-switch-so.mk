# Builds Flycast (Dreamcast/Naomi) as a dynamic aarch64 .so for onoke's
# loader. Same pattern as mupen64plus-next's: the core's Makefile with platform=libnx
# already carries STATIC_LINKING=1 and WITH_DYNAREC=arm64, so it produces a .a with every
# .o and we relink that as a .so.
#
# Usage (a shell with DEVKITPRO set, devkitPro's MSYS2):
#   make -f switch-so.mk -j4
# Output: flycast_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Differences from mupen's:
#  - The version script is in the ROOT (link.T), not in libretro/.
#  - TARGET_NAME is "flycast" -> the partial is flycast_libretro_libnx.a.
#
# BIOS: Flycast emulates the boot through HLE for most Dreamcast games, but Naomi and some
# titles want dc_boot.bin / dc_flash.bin. Those files come from your own console and go in
# the system directory; they do not ship with this.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := flycast_libretro_libnx.a

# A C++ core: libstdc++ goes inside, statically. The version script leaves those symbols
# LOCAL, so they do not clash with the host's libstdc++; the libretro API is C and no C++
# objects cross.
flycast_libretro.so: $(PARTIAL)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  -Wl,--version-script=link.T \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

# Forces the core's official build (which produces the .a).
$(PARTIAL): FORCE
	$(MAKE) platform=libnx BASKE_LIBRETRO_COMMON=1 -j4

FORCE:

clean:
	$(MAKE) platform=libnx BASKE_LIBRETRO_COMMON=1 clean
	rm -f flycast_libretro.so

.PHONY: clean FORCE
