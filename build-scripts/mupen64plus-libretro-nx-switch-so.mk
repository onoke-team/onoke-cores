# Builds mupen64plus-next (N64) as a dynamic aarch64 .so for onoke's loader.
# The core is C++11 (no RTTI), with a dynarec of its own for aarch64 and HARDWARE rendering
# (GLideN64 through glsm) -> the frontend gives it the GL context.
#
# Usage (a shell with DEVKITPRO set, devkitPro's MSYS2):
#   make -f switch-so.mk -j4
# Output: mupen64plus_next_libretro.so  -> sdmc:/switch/onoke/cores/
#
# How it works:
#  1) `make platform=libnx` (the core's Makefile) -> includes base_tools (which pins the
#     devkitA64 toolchain by itself), STATIC_LINKING=1 ->
#     `mupen64plus_next_libretro_libnx.a` (every .o).
#  2) THAT .a is relinked as a .so with our flags: -shared -nostdlib
#     --unresolved-symbols=ignore-all (libc/libstdc++/GL are resolved by the HOST through
#     resolveSelf/HOST_SYMS in dynlib.cpp), --whole-archive (pulls in EVERY .o of the .a),
#     --version-script=libretro/link.T (exports retro_* only), --hash-style=sysv (the
#     loader uses DT_HASH), -lgcc (compiler routines).
#
# The dynarec uses switch/mman.h (virtmemReserve + svcMapProcessMemory) for the jit; those
# symbols are forced into the host with -Wl,-u in CMakeLists.txt. The loader also runs the
# .init_array (C++ global constructors). No N64 BIOS is needed (HLE).

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := mupen64plus_next_libretro_libnx.a

# A C++ core: libstdc++ is linked in STATICALLY (the host does not export all of
# iostream/regex/locale; the libretro API is C and no C++ objects cross -> self-contained
# and safe). The version script leaves those symbols LOCAL (they do not clash with the
# host's libstdc++).
mupen64plus_next_libretro.so: $(PARTIAL)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  -Wl,--version-script=libretro/link.T \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

# Forces the core's official build (which produces the .a).
$(PARTIAL): FORCE
	$(MAKE) platform=libnx -j4

FORCE:

clean:
	$(MAKE) platform=libnx clean
	rm -f mupen64plus_next_libretro.so

.PHONY: clean FORCE
