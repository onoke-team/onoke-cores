# Builds FinalBurn Neo (arcade, Neo Geo, CPS1/2/3) as a dynamic aarch64 .so for onoke's
# loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: fbneo_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Same pattern as the rest: upstream's libnx target (src/burner/libretro/Makefile line 302)
# sets STATIC_LINKING=1 and leaves a .a, and we relink it as a .so with what the loader
# needs -- sysv hashes (it walks DT_HASH) and unresolved symbols left to the host (see
# HOST_SYMS and resolveSelf in src/emu/dynlib.cpp).
#
# THE LONGEST BUILD OF THE SET, by a distance: FBNeo compiles thousands of drivers, each
# one an arcade board. Nothing to do about it -- that IS the core.
#
# ROMs and BIOS: FBNeo is strict about the SET. Its ROMs are zips whose contents have to
# match the version of the driver in this build, and Neo Geo needs neogeo.zip as its BIOS,
# from your own machines. A set from another version fails to load and says almost nothing
# about why -- when a game does not start, that is the first thing to check.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
LR      := src/burner/libretro
PARTIAL := $(LR)/fbneo_libretro_libnx.a

LRC := $(LR)/libretro-common

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
  -I$(LRC)/include -I $(LR) -I$(DEVKITPRO)/libnx/include

fbneo_libretro.so: $(PARTIAL) $(EXTRA_OBJS)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  $(EXTRA_OBJS) \
	  -Wl,--version-script=$(LR)/link.T \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@$(DKA64)strip --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

# The archive is built through a RESPONSE FILE (see patches/FBNeo/local-changes.patch):
# with thousands of drivers, `ar rcs` with every object on one line goes past what the
# shell takes ("Argument list too long"). Upstream has a SPLIT_UP_LINK path meant for this,
# but it expands a $(NEWLINE) variable that this Makefile never defines, so it collapses
# into the same single line. Same fix as Flycast and mupen on Windows.
$(PARTIAL): FORCE
	$(MAKE) -C $(LR) platform=libnx -j4

FORCE:

%.o: %.c
	$(CC) $(EXTRA_CFLAGS) -c $< -o $@

clean:
	$(MAKE) -C $(LR) platform=libnx clean
	rm -f $(EXTRA_OBJS) fbneo_libretro.so

.PHONY: clean FORCE
