# Builds Genesis Plus GX as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: genesis_plus_gx_libretro.so  -> sdmc:/switch/onoke/cores/
#
# FIVE SYSTEMS in one core: Mega Drive/Genesis, Sega CD/Mega CD, Master System, Game Gear
# and SG-1000. That is why it came first -- no other core in the list covers so much for
# one build.
#
# Same pattern as melonDS/mupen/flycast: upstream's libnx target (Makefile.libretro line
# 423) sets STATIC_LINKING=1 and leaves a .a, and we relink it as a .so with the flags the
# loader needs -- sysv hashes (it walks DT_HASH) and unresolved symbols left to the host
# (see HOST_SYMS and resolveSelf in src/emu/dynlib.cpp).
#
# Pure C and pure software: no GL, no dynarec, no threads.
#
# THE LIBRETRO-COMMON GAP (the same one as Flycast and melonDS, third time): under
# STATIC_LINKING the core leaves out part of libretro-common, because it assumes it is
# linked inside RetroArch and RetroArch supplies those symbols. We are not RetroArch: the
# .so came out with filestream_*, rf*, fill_pathname_join and strl*_retro__ unresolved.
# Here they are compiled and linked in ALONGSIDE the .a instead of patching upstream --
# this core needs no other patch, and a build script beats a patch that has to be rebased.
#
# BIOS: only Sega CD needs one (bios_CD_E/U/J.bin in system/), and it has to come from your
# own console. Everything else boots with the ROM alone.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := genesis_plus_gx_libretro_libnx.a

LRC := libretro/libretro-common

# What the .a leaves unresolved, and nothing else: this is not "add libretro-common", it is
# the exact set the linker asked for.
EXTRA_SRCS := \
  $(LRC)/streams/file_stream.c \
  $(LRC)/streams/file_stream_transforms.c \
  $(LRC)/vfs/vfs_implementation.c \
  $(LRC)/file/file_path.c \
  $(LRC)/compat/compat_strl.c \
  $(LRC)/compat/compat_strcasestr.c \
  $(LRC)/encodings/encoding_utf.c \
  zstd_trace_stub.c

EXTRA_OBJS := $(EXTRA_SRCS:.c=.o)

# -DSWITCH=1 as well as __SWITCH__: libretro-common's memmap.h asks for SWITCH (that
# spelling, no underscores) to know there is no mman here, and gpgx's libnx target only
# defines __SWITCH__ -- upstream never noticed because under STATIC_LINKING it does not
# compile this file at all. Without it, vfs_implementation.c goes looking for sys/mman.h.
EXTRA_CFLAGS := -O2 -fPIC -ffunction-sections -fdata-sections \
  -march=armv8-a -mtune=cortex-a57 \
  -DSWITCH=1 -D__SWITCH__ -DHAVE_LIBNX -D__LIBRETRO__ -DHAVE_STDINT_H \
  -I$(LRC)/include -I$(DEVKITPRO)/libnx/include

genesis_plus_gx_libretro.so: $(PARTIAL) $(EXTRA_OBJS)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  $(EXTRA_OBJS) \
	  -Wl,--version-script=libretro/link.T \
	  -o $@ $(LIBGCC)
	@$(DKA64)strip --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

# zstd (used by libchdr for Sega CD) calls these two when built with tracing on, and
# upstream does not define them -- it leaves them for whoever links the library. Empty is
# what tracing off means; without them the calls jump to a null address on the first .chd.
zstd_trace_stub.c:
	@echo 'unsigned long long ZSTD_trace_decompress_begin(void* c){(void)c;return 0;}' > $@
	@echo 'void ZSTD_trace_decompress_end(void* t){(void)t;}' >> $@

$(PARTIAL): FORCE
	$(MAKE) -f Makefile.libretro platform=libnx -j4

FORCE:

%.o: %.c
	$(CC) $(EXTRA_CFLAGS) -c $< -o $@

clean:
	$(MAKE) -f Makefile.libretro platform=libnx clean
	rm -f $(EXTRA_OBJS) zstd_trace_stub.c genesis_plus_gx_libretro.so

.PHONY: clean FORCE
