# Builds vba-next as a dynamic aarch64 .so for onoke's loader.
#
# Usage (a shell with DEVKITPRO set, e.g. devkitPro's MSYS2):
#   make -f switch-so.mk
#
# Output: vba_next_libretro.so  -> copy it to sdmc:/switch/onoke/cores/
#
# The key flags: -shared -fPIC (relocatable PIE), --hash-style=sysv (the loader uses
# DT_HASH), -nostdlib plus --unresolved-symbols=ignore-all (libc is resolved by the HOST
# through HOST_SYMS in dynlib.cpp), and -lgcc for the compiler routines (__aeabi_* and so
# on).

CC     := $(DEVKITPRO)/devkitA64/bin/aarch64-none-elf-gcc
LIBGCC := $(shell $(CC) -print-libgcc-file-name)

COMMON := libretro-common

CFLAGS := -O2 -g -fPIC -ffunction-sections -fdata-sections \
  -march=armv8-a -mtune=cortex-a57 \
  -D__LIBRETRO__ -DHAVE_HLE_BIOS -DINLINE=inline -DFRONTEND_SUPPORTS_RGB565 \
  -DHAVE_STDINT_H -DLOAD_FROM_MEMORY \
  -I. -I$(COMMON)/include

SRCS := \
  src/sound.c src/memory.c src/gba.c src/system.c \
  libretro/libretro.c \
  $(COMMON)/memalign.c \
  $(COMMON)/compat/compat_posix_string.c \
  $(COMMON)/compat/compat_strcasestr.c \
  $(COMMON)/compat/compat_snprintf.c \
  $(COMMON)/compat/compat_strl.c \
  $(COMMON)/compat/fopen_utf8.c \
  $(COMMON)/encodings/encoding_utf.c \
  $(COMMON)/file/file_path.c \
  $(COMMON)/file/file_path_io.c \
  $(COMMON)/streams/file_stream.c \
  $(COMMON)/string/stdstring.c \
  $(COMMON)/time/rtime.c \
  $(COMMON)/vfs/vfs_implementation.c

OBJS := $(SRCS:.c=.o)

vba_next_libretro.so: $(OBJS)
	$(CC) -shared -fPIC -nostdlib \
	  -Wl,--hash-style=sysv -Wl,--unresolved-symbols=ignore-all \
	  -o $@ $(OBJS) $(LIBGCC)
	@echo "OK -> $@ (copy to sdmc:/switch/onoke/cores/)"

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) vba_next_libretro.so

.PHONY: clean
