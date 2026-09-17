# Builds DOSBox Pure as a dynamic aarch64 .so for onoke's loader.
#
# Usage (devkitPro's MSYS2 shell, with DEVKITPRO set):
#   make -f switch-so.mk -j4
# Output: dosbox_pure_libretro.so  -> sdmc:/switch/onoke/cores/
#
# DOS on the console, which is what this one is here for: it takes the whole game as a .zip
# and mounts it as drive C:, so nothing has to be installed and a game is one file in the
# library. It is also the only core in the list that needs a keyboard -- see its own on-screen
# one, which is why it wants the pad's buttons free.
#
# Same pattern as the rest: upstream's libnx target (Makefile line 129) sets STATIC_LINKING=1
# and leaves a .a, and we relink it as a .so with what the loader needs -- sysv hashes (it
# walks DT_HASH) and unresolved symbols left to the host (see HOST_SYMS and resolveSelf in
# src/emu/dynlib.cpp).
#
# NO VERSION SCRIPT: upstream ships no link.T, so the whole dynamic table is exported instead
# of the retro_* set alone. It costs a bigger symbol table and nothing else -- the loader
# looks up what it needs by name.
#
# C++ with exceptions (the Makefile turns them on with -fexceptions), so the standard library
# goes IN: unlike the C cores, this one cannot leave __cxa_* and operator new to the host,
# which does not export them.

DKA64  := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-
CXX    := $(DKA64)g++
LIBGCC := $(shell $(CXX) -print-libgcc-file-name)
PARTIAL := dosbox_pure_libretro_libnx.a

dosbox_pure_libretro.so: $(PARTIAL)
	$(CXX) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -Wl,--whole-archive $(PARTIAL) -Wl,--no-whole-archive \
	  -o $@ -lstdc++ -lsupc++ $(LIBGCC)
	@$(DKA64)strip --strip-debug $@
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

$(PARTIAL): FORCE
	$(MAKE) -f Makefile platform=libnx -j4

FORCE:

clean:
	$(MAKE) -f Makefile platform=libnx clean
	rm -f dosbox_pure_libretro.so

.PHONY: clean FORCE
