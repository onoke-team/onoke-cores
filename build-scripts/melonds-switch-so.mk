# Builds melonDS (Nintendo DS) as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: melonds_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Unlike PPSSPP, upstream here DOES have a maintained libnx target (Makefile line 221)
# with STATIC_LINKING=1, so it is the same pattern as mupen64plus-next and flycast: the
# core's Makefile leaves a .a and we relink it as a .so.
#
# Particulars:
#  - The version script is in src/libretro/link.T, not the root.
#  - Makefile.common DOES omit part of libretro-common under STATIC_LINKING (like
#    Flycast), so BASKE_LIBRETRO_COMMON=1 is needed. See patches/README.md.
#
# BIOS: dumping your console's is NOT needed. melonDS ships DraStic's free replacements in
# freebios/ (drastic_bios_arm7.bin / arm9.bin) and boots straight into the ROM.
#
# JIT: upstream's libnx target ships it DISABLED on purpose (Makefile line 233,
# "#JIT_ARCH = aarch64 # TODO: Re-add when armjit memory problems are fixed upstream"), and
# without it this is a pure interpreter and runs slow. Re-enabling it also means exporting
# __libnx_exception_handler in the version script: melonDS's JIT emulates virtual memory by
# trapping page faults and defines it in src/ARMJIT_Memory.cpp, like Flycast.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := melonds_libretro_libnx.a

melonds_libretro.so: $(PARTIAL)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  -Wl,--version-script=src/libretro/link.T \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

$(PARTIAL): FORCE
	$(MAKE) platform=libnx BASKE_LIBRETRO_COMMON=1 -j4

FORCE:

clean:
	$(MAKE) platform=libnx clean
	rm -f melonds_libretro.so

.PHONY: clean FORCE
