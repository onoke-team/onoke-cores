# Builds Citra (Nintendo 3DS) as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: citra_libretro.so  -> sdmc:/switch/onoke/cores/
#
# Same pattern as melonDS/flycast/mupen: upstream has a libnx target with
# STATIC_LINKING=1, it leaves a .a and we relink that as a .so.
#
# Particulars:
#  - The version script is in src/citra_libretro/link.T, not the root.
#  - The Makefile already carries -D__LINUX_ERRNO_EXTENSIONS__ (what PPSSPP was missing,
#    which made ESHUTDOWN not exist), HAVE_RGLGEN=1 (glsym, like the rest) and HAVE_GLAD=0.
#
# PERFORMANCE EXPECTATION -- read before putting time in here:
# The 3DS has a dual-core ARM11 plus a PICA200 GPU whose shaders have to be recompiled on
# the fly. Citra on Android wants a high-end phone (Snapdragon 855+, cores at ~2.8 GHz) for
# full speed in many games; the Switch has Cortex-A57 at 1.02 GHz handheld. Even with the
# JIT, expect the heavy 3D titles not to make it. This was tried because the build path was
# already known and finding out came cheap, not because there was a founded expectation
# that it would perform.
#
# BIOS: Citra needs no BIOS, but it DOES need the 3DS system files for several games
# (shared fonts and so on). Those come from your own console.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CC     := $(DKA64)gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)
PARTIAL := citra_libretro_libnx.a

citra_libretro.so: $(PARTIAL)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  -Wl,--version-script=src/citra_libretro/link.T \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

$(PARTIAL): FORCE
	# MANDATORY. Dependency tracking in this build does NOT work: devkitPro's pattern
	# rules (switch_rules -> base_rules) beat Citra's for every .cpp, so a modified header
	# recompiles NOTHING -- the .so comes out identical, with the old code inside, and the
	# build reports success. Every .o older than the newest source/header is deleted so the
	# next compile really reflects what is in the tree.
	@newest=$$(ls -t Makefile Makefile.common $$(find src externals -name '*.h' -o -name '*.hpp' -o -name '*.cpp' -o -name '*.c' 2>/dev/null) 2>/dev/null | head -1); \
	 if [ -n "$$newest" ]; then \
	     stale=$$(find . -name '*.o' ! -newer "$$newest" | wc -l); \
	     if [ "$$stale" -gt 0 ]; then \
	         echo ">> $$stale objects older than $$newest: deleting (broken deps, see the comment)"; \
	         find . -name '*.o' ! -newer "$$newest" -delete; \
	         rm -f $(PARTIAL); \
	     fi; \
	 fi
	# genfiles first: it generates externals/glslang/build/glslang/build_info.h and
	# src/common/scm_rev.cpp. Citra's "%.o: %.cpp" rule carries them as a prerequisite, but
	# devkitPro's (base_rules, pulled in by switch_rules) is the one that wins for every
	# .cpp and does not have them, so they have to be asked for by hand.
	$(MAKE) platform=libnx genfiles
	$(MAKE) platform=libnx -j4

FORCE:

clean:
	$(MAKE) platform=libnx clean
	rm -f citra_libretro.so

.PHONY: clean FORCE
