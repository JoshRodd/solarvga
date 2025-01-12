# solarvga

v0.9.1  
12 January 2025

## Introduction

This is an implementation of [Ethan Schoonover's
Solarized](https://ethanschoonover.com/solarized/) for DOS and IBM PC
compatibles that have a VGA card (including virtual machines, emulators,
or environments like DOSBox).

## Warning

Version 0.9.1 has a bug in its .SYS driver and does not work. The .COM TSR
works properly.

It also has a bug where it does not function properly in PCjs's implementation
of a VGA.

## Compatibility

Compatible with MS-DOS 1.00 or PC-DOS 1.00 and up alongside a VGA, MCGA, or
100% compatible (any PS/2 or any PC with a PS/2 Display Adapter or 100% VGA
compatible).

Test with DOSBox-X and 86Box (PS/2 Display Adapter, Trident TVGA8900B, and
Tseng Labs ET4000AX), and PC-DOS 1.00.

The uninstall option does not work properly on PC-DOS 1.00 due to not
supporting the way PC-DOS 1.00 presents command-line arguments.

## Using

It can be run as a TSR (optionally with `LOADHIGH`), or installed as a device
driver (on DOS 2.00 or newer). Installing as a device driver saves
approximately 448 bytes of memory (432 bytes on DOS versions prior to 2.00).
The device driver can be installed with `DEVICEHIGH`, and consumes
approximately 176 bytes of memory.

You can add it to `CONFIG.SYS` with something like this:

```
DEVICE=A:\SOLARVGA.COM
```

or to `AUTOEXEC.BAT` like this:

```
@A:\SOLARVGA
```

The program can be removed from resident memory by running `SOLARVGA /U`. Note
that on DOS versions prior to 2.00, the memory cannot be freed when
uninstalled.

## Building

Run `make`, `MAKE.BAT`, or `make.sh`; requires nasm, although it will also
build with [A86](http://eji.com/a86/). Note that `SOLARVGA.COM` and
`SOLARVGA.SYS` are identical.

## Licence

Copyright © 2025 Josh Rodd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
