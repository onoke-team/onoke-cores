# onoke-cores

The libretro cores [Onoke](https://github.com/onoke-team/onoke-releases) downloads, and the
patches they are built with.

They do not travel inside the app: most of them are GPL and the app is not. Each one keeps
its own licence, and this repo is what answers for the binaries -- for every core it hands
out, the source it came from is named here down to the commit.

## What is published

| core | systems | Switch | Windows |
|---|---|:--:|:--:|
| Azahar | Nintendo 3DS |  | yes |
| FinalBurn Neo | Arcade, Neo Geo, CPS1, CPS2, CPS3 | yes | yes |
| FCEUmm | Nintendo Entertainment System, Famicom | yes | yes |
| Flycast | Dreamcast, Naomi, Atomiswave | yes | yes |
| Gambatte | Game Boy, Game Boy Color | yes | yes |
| Genesis Plus GX | Mega Drive, Sega CD, Master System, Game Gear, SG-1000 | yes | yes |
| melonDS | Nintendo DS | yes | yes |
| mGBA | Game Boy Advance, Game Boy, Game Boy Color | yes | yes |
| Mupen64Plus-Next | Nintendo 64 | yes | yes |
| PCSX ReARMed | PlayStation | yes | yes |
| Snes9x | Super Nintendo | yes | yes |
| VBA Next | Game Boy Advance | yes | yes |

A core missing from a column is not built for that platform yet.

## Releases

| tag | what it carries |
|---|---|
| `cores-switch`  | the Switch `.so` files and `cores-switch.json` |
| `cores-windows` | the Windows `.dll` files and `cores-windows.json` |

They are moving tags: they always point at the latest build, because the app asks for a
fixed URL. The app reads its platform's manifest, checks the sha256 of what it downloads,
and only then installs it.

## What is in here

- **one folder per core** -- what had to be changed to build it. Nearly all of it is
  porting: making it compile for aarch64, getting the JIT executable memory on the console,
  keeping its OpenGL state from treading on the interface's.
- **`build-scripts/`** -- the recipe each one is built with.
- **`cores.lock.json`** -- which repository and which exact commit each core comes
  from, the recipe that builds it and the binary it produces.

## Building one yourself

Everything needed is in the lock, per core and per platform. For `<core>`, read its
entry there and:

```sh
git clone <repo>  <dir>          # the "repo" field
cd <dir> && git checkout <commit>  # "commit": not master -- a patch off its base applies crooked
git apply /path/to/onoke-cores/<core>/*.patch
<recipe>                          # the "recipe" field, run from that directory
```

The result is the same binary published here, save for the timestamps a compiler puts in.
An older build is rebuilt the same way, from the commit that release's lock kept.

## Licences

Each core is its upstream's work and keeps its licence -- most are GPLv2 or GPLv3. Nothing
here is part of Onoke, and Onoke's own licence does not extend to any of it. The patches in
this repo are offered under the licence of the project each one patches.