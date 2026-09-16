# Builds FCEUmm (NES / Famicom) as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: fceumm_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Same pattern as the rest: upstream's libnx target (Makefile.libretro line 327) sets
# STATIC_LINKING=1 and leaves a .a, and we relink it as a .so with what the loader needs --
# sysv hashes (it walks DT_HASH) and unresolved symbols left to the host (see HOST_SYMS and
# resolveSelf in src/emu/dynlib.cpp).
#
# Pure C, software rendering, no BIOS. The lightest core in the whole set.
#
# THE LIBRETRO-COMMON GAP: under STATIC_LINKING the core leaves out part of
# libretro-common, assuming RetroArch supplies those symbols. We are not RetroArch, so what
# the linker asks for is compiled here alongside the .a -- like Genesis Plus GX and Snes9x.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := fceumm_libretro_libnx.a

LRC := src/drivers/libretro/libretro-common

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
  -I$(LRC)/include -I src/drivers/libretro -I$(DEVKITPRO)/libnx/include

fceumm_libretro.so: $(PARTIAL) $(EXTRA_OBJS)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  $(EXTRA_OBJS) \
	  -Wl,--version-script=src/drivers/libretro/link.T \
	  -o $@ $(LIBGCC)
	@$(DKA64)strip --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

$(PARTIAL): FORCE
	$(MAKE) -f Makefile.libretro platform=libnx -j4

FORCE:

%.o: %.c
	$(CC) $(EXTRA_CFLAGS) -c $< -o $@

clean:
	$(MAKE) -f Makefile.libretro platform=libnx clean
	rm -f $(EXTRA_OBJS) fceumm_libretro.so

.PHONY: clean FORCE
