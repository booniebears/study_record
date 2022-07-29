.org 0x0
.set noat
.set noreorder
.set nomacro

.global _start
_start:
    ori     $2,$0,0x41                      # 'a'
    sb		$2, 0x4000($0)		# 
loop:
    j		loop				            # jump to loop
    nop
