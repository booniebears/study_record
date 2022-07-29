# Introduction
NJU_MIPS is course project for Experimemts in Digital Logit Circuits. It is a MIPS32 system with 5 levels pipeline CPU.

# Instruction
| NAME    | FUNCTION                          |
| ----    | --------                          |
| ./hello | show "Hello World"                |
| ./fib   | show nth fibbonaci number         |
| ./gdb   | step over demo programme          |
| ./mu    | open digital piano(cannot return) |

# Attributes
* CPU Frequency : 12.5MHz
* Align: Big Endian
* Memory Size : 128KB
* Instruction ROM Size : 4KB
* Support Instruction: All supported expect ones with coprocessor and interrupt. (ll, sc is not implemented)

# MMIO structure
| ADDRESS             | DESCRIPTION         | FUNCTION                                    |
| ------------------- | ------------------- | ---------------------                       |
| 0x000000 - 0x003900 | ROM for instruction | executable; lw only                         |
| 0x003900 - 0x004000 | RAM for instruction | executable; lw,sw only                      |
| 0x004000 - 0x005000 | GRAM for video      | readable, writable; access by vga(640\*480) |
| 0x005000            | keyboard enable     | lb only                                     |
| 0x005004            | keyboard ascii      | lb only                                     |
| 0x005008            | audio enable        | wb only                                     |
| - 0x006000          | Reserve             |                                             |
| 0x006000 - 0x008000 | RAM:Data Section    |                                             |
| 0x008000 - 0x010000 | RAM:Heap            |                                             |

# AM
AM is introduced in our ics lessons. We add MIPS32 AM to support C program. In test of AM, if succeed, you will see AC in the monitor. Otherwise, WA is shown. For now, dummy.c is tested.

# Load Code
Code will be load into inst_rom from inst_rom.mif in program. You can use Makefile to generate mif file from .s file. Or you can generate mif file from binary(.data) file. Compilation may takes about 4mins.

# Simulation
## Modelsim Altera
  Test bench is sopc\_tst.v in simulation/modelsim, top module should be sopc\_tst. watchreg.do helps trace all regs value in hex.
### Icuras Verilog with scansion
  For mac user, this lite tools is introduced. However, array variables cannot be seen.

# IP Core Used
* inst\_rom\_ip: 2-PORT ROM, 4096*32, inst_rom.mif
* data\_ram\_ip: 2-PORT RAM, 16384*8, blank
* ascii2pcode:  1-PORT ROM, 4096*12, a2c.mif
* video\_ram\_ip0~4: 2-PORT RAM, 1024*8, vm.mif
* kb(_shift)_rom: 1-PORT ROM, 256*8, c2a.mif
* sintable: 1-PORT ROM, 1024*16, sintable.mif
* c2f: 1-PORT ROM, 256*16, c2f.mif
* xck: Altera PLL
