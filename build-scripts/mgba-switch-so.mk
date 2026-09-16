# Relinks mGBA's static core (built by ../../build-gba.sh through CMake) as a dynamic
# aarch64 .so for onoke's loader.
#
#   make -f switch-so.mk        # after build-gba.sh has produced the .a
#
# Output: mgba_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Same relink as every other core: sysv hashes (the loader walks DT_HASH), unresolved
# symbols left to the host (see HOST_SYMS and resolveSelf in src/emu/dynlib.cpp) and the
# version script so only the retro_* API is exported.
#
# The .a comes out of CMake, not of a libretro Makefile, so there is no libretro-common gap
# to patch here: mGBA brings its own VFS (CORE_VFS_SRC) and does not lean on RetroArch's.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := build-nx/mgba_libretro.a

mgba_libretro.so: $(PARTIAL)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  -Wl,--version-script=src/platform/libretro/link.T \
	  -o $@ $(LIBGCC)
	@$(DKA64)strip --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

clean:
	rm -f mgba_libretro.so

.PHONY: clean
