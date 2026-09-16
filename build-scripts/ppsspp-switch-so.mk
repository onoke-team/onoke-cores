# Builds PPSSPP (PSP) as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   ./build-psp.sh          from the project root
# or by hand:
#   make -f switch-so.mk -j4
# Output: ppsspp_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Differences from the other cores (mupen, flycast, pcsx_rearmed, vba-next):
#
#  - Those build with "make platform=libnx" and STATIC_LINKING=1, which leaves ONE .a with
#    everything inside. PPSSPP builds with CMake and leaves 31 separate files in
#    build-nx/lib/ (libCore.a carries all of GPU/ as well), so they all have to be joined
#    here with --start-group/--end-group to resolve the circular dependencies between them.
#
#  - The configure is neither optional nor trivial: see build-psp.sh, which has the exact
#    flags and the reason for each (msys's cmake has to be used, not mingw64's, and
#    CMAKE_DEPENDS_USE_COMPILER=OFF).
#
#  - PPSSPP does not define __libnx_exception_handler (it uses an explicit
#    svcMapProcessMemory, not lazy page faults like flycast), so its stock link.T
#    -- global: retro_* -- is enough as it stands and needs no touching.
#
# BIOS: PPSSPP needs no PSP BIOS, it emulates the firmware through HLE.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
STRIP  := $(DKA64)strip
LIBGCC := $(shell $(CC) -print-libgcc-file-name)

BUILD  := build-nx
LIBDIR := $(BUILD)/lib
CORE   := $(LIBDIR)/ppsspp_libretro.a
# Everything else in the tree: Core (which includes GPU/), Common and the vendored deps.
DEPS   := $(filter-out $(CORE),$(wildcard $(LIBDIR)/*.a))

ppsspp_libretro.so: $(CORE) $(DEPS)
	@test -n "$(DEPS)" || { echo "No .a in $(LIBDIR): build with build-psp.sh first"; exit 1; }
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(CORE) -Wl,--no-whole-archive \
	  -Wl,--start-group $(DEPS) -Wl,--end-group \
	  -Wl,--version-script=libretro/link.T \
	  -L$(DEVKITPRO)/portlibs/switch/lib -lpng -lz \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	$(STRIP) --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

clean:
	rm -f ppsspp_libretro.so

.PHONY: clean
