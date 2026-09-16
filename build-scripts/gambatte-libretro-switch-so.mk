# Builds Gambatte (Game Boy / Game Boy Color) as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: gambatte_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Same pattern as the rest: upstream's libnx target (Makefile.libretro line 346) sets
# STATIC_LINKING=1 and leaves a .a, and we relink it as a .so with what the loader needs --
# sysv hashes (it walks DT_HASH) and unresolved symbols left to the host (see HOST_SYMS and
# resolveSelf in src/emu/dynlib.cpp).
#
# WHY GAMBATTE AND NOT mGBA for Game Boy: mGBA covers GB, GBC and GBA in one core and is
# more accurate, but the libretro fork builds through CMake (like PPSSPP), which is a
# different and longer road. The GAP was GB/GBC -- there was no core at all -- and Gambatte
# fills it with the recipe that is already solved. mGBA stays as an upgrade of something
# that already works (GBA, on vba_next), not as a hole.
#
# C++ core, hence -lstdc++ -lsupc++ at the link. No BIOS: it boots the ROM on its own.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := gambatte_libretro_libnx.a

LRC := libgambatte/libretro-common

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
  -I$(LRC)/include -I libgambatte/libretro -I$(DEVKITPRO)/libnx/include

gambatte_libretro.so: $(PARTIAL) $(EXTRA_OBJS)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  $(EXTRA_OBJS) \
	  -Wl,--version-script=libgambatte/libretro/link.T \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@$(DKA64)strip --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

$(PARTIAL): FORCE
	$(MAKE) -f Makefile.libretro platform=libnx -j4

FORCE:

%.o: %.c
	$(CC) $(EXTRA_CFLAGS) -c $< -o $@

clean:
	$(MAKE) -f Makefile.libretro platform=libnx clean
	rm -f $(EXTRA_OBJS) gambatte_libretro.so

.PHONY: clean FORCE
