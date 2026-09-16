# Builds PCSX ReARMed (PSX) as a dynamic aarch64 .so for onoke's loader,
# WITH THE DYNAREC (ari64) = maximum performance (the same one RetroArch uses on Switch).
#
# Usage (a shell with DEVKITPRO set, devkitPro's MSYS2):
#   make -f switch-so.mk -j4
#
# Output: pcsx_rearmed_libretro.so  -> copy it to sdmc:/switch/onoke/cores/
# Requires the user's OWN PSX BIOS in sdmc:/switch/onoke/system/
#   (scph1001.bin / scph5501.bin / scph7502.bin, say). No BIOS is distributed.
#
# How it works:
#  1) It runs the official `platform=libnx` build (Makefile.libretro). That target uses
#     PARTIAL_LINKING: `ld -r --gc-sections` over EVERY .o into a single relocatable
#     object `pcsx_rearmed_libretro_libnx.o` with ONLY the retro_* symbols global (the
#     rest localised). The ari64 dynarec ends up inside.
#  2) THAT object is relinked as a .so with our flags: -shared -nostdlib
#     --unresolved-symbols=ignore-all (libc AND the dynarec's libnx functions --
#     jitCreate/jitTransition/armDCache*/armICacheInvalidate -- are resolved by the HOST
#     through HOST_SYMS in src/emu/dynlib.cpp), --hash-style=sysv (the loader uses
#     DT_HASH), -lgcc for compiler routines (__aeabi_*, __clear_cache and so on).
#
# The Makefile's libnx block does NOT pin the toolchain prefix, so it is passed
# explicitly (devkitA64).

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)

# Name of the partial object PARTIAL_LINKING produces (the basename of the TARGET .a).
PARTIAL := pcsx_rearmed_libretro_libnx.o

# Recompiler: ari64 (NEON, the libnx block's default) is what is used; lightrec (GNU
# Lightning) is an alternative with different codegen. Override with:
#   make -f switch-so.mk DYNAREC=lightrec
DYNAREC ?= ari64

TOOLS := CC=$(DKA64)gcc CXX=$(DKA64)g++ AS=$(DKA64)as LD=$(DKA64)ld \
         AR=$(DKA64)ar OBJCOPY=$(DKA64)objcopy DYNAREC=$(DYNAREC)

pcsx_rearmed_libretro.so: $(PARTIAL)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -o $@ $(PARTIAL) $(LIBGCC)
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

# Forces the official build (which produces the .a and, with it, the $(PARTIAL)).
$(PARTIAL): FORCE
	$(MAKE) -f Makefile.libretro platform=libnx $(TOOLS)

FORCE:

clean:
	$(MAKE) -f Makefile.libretro platform=libnx $(TOOLS) clean
	rm -f pcsx_rearmed_libretro.so

.PHONY: clean FORCE
