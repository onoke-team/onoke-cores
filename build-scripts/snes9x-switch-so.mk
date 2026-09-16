# Builds Snes9x (SNES) as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: snes9x_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Same pattern as the rest: upstream's libnx target (libretro/Makefile line 147) sets
# STATIC_LINKING=1 and leaves a .a, and we relink it as a .so with what the loader needs --
# sysv hashes (it walks DT_HASH) and unresolved symbols left to the host (see HOST_SYMS and
# resolveSelf in src/emu/dynlib.cpp).
#
# C++ core, hence -lstdc++ -lsupc++ at the link (melonDS and Flycast need the same).
# Software renderer and no dynarec: nothing here strains the console.
#
# THE LIBRETRO-COMMON GAP: under STATIC_LINKING the core leaves out part of
# libretro-common, assuming it is linked inside RetroArch and RetroArch supplies those
# symbols. We are not RetroArch, so what the linker asks for is compiled here alongside the
# .a -- the same as Genesis Plus GX, and without patching a tree that needs no other patch.
#
# BIOS: none. SNES ROMs boot on their own.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := libretro/snes9x_libretro_libnx.a

LRC := libretro/libretro-common

EXTRA_SRCS := \
  $(LRC)/streams/file_stream.c \
  $(LRC)/streams/file_stream_transforms.c \
  $(LRC)/vfs/vfs_implementation.c \
  $(LRC)/file/file_path.c \
  $(LRC)/file/file_path_io.c \
  $(LRC)/compat/compat_strl.c \
  $(LRC)/encodings/encoding_utf.c

EXTRA_OBJS := $(EXTRA_SRCS:.c=.o)

# -DSWITCH=1 as well as __SWITCH__: libretro-common's memmap.h asks for SWITCH (that
# spelling) to know there is no mman here.
EXTRA_CFLAGS := -O2 -fPIC -ffunction-sections -fdata-sections \
  -march=armv8-a -mtune=cortex-a57 \
  -DSWITCH=1 -D__SWITCH__ -DHAVE_LIBNX -D__LIBRETRO__ -DHAVE_STDINT_H \
  -I$(LRC)/include -I libretro -I$(DEVKITPRO)/libnx/include

snes9x_libretro.so: $(PARTIAL) $(EXTRA_OBJS)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  $(EXTRA_OBJS) \
	  -Wl,--version-script=libretro/link.T \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@$(DKA64)strip --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

$(PARTIAL): FORCE
	$(MAKE) -C libretro platform=libnx -j4

FORCE:

%.o: %.c
	$(CC) $(EXTRA_CFLAGS) -c $< -o $@

clean:
	$(MAKE) -C libretro platform=libnx clean
	rm -f $(EXTRA_OBJS) snes9x_libretro.so

.PHONY: clean FORCE
