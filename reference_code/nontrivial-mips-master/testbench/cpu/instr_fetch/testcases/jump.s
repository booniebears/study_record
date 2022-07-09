	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
	nop
	j dest_1
	nop
	nop
	nop
dest_1:
	j dest_2
	nop
	nop
dest_2:
	nop

# %BEGIN CONTROLFLOW%
# 0 None
# 1 JumpImm
# 2 None
# 5 JumpImm
# 6 None
# 8 None
# %END CONTROLFLOW%
