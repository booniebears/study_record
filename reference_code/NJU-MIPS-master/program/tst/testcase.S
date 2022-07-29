.org 0x0
.set noat
.set noreorder
.set nomacro

.global _start
_start:
    ori     $2,$0,0x41                      # 'a'
    #ori     $7,$31,0x0
    ori     $14,$0,0x3900
    ori     $15,$0,0x2ef0
    lw		$16, 0($15)		                # 
    sw		$16, 0($14)		                # 0x3900
    addi	$15, $15, 0x04			        # $15 = $15 + 0x04
    addi	$15, $15, 0x04			        # $15 = $15 + 0x04
    lw		$16, 0($15)		                # 
    sw		$16, 0($14)		                # 0x3904
    addi	$15, $15, 0x04			        # $15 = $15 + 0x04
    addi	$15, $15, 0x04			        # $15 = $15 + 0x04
    lw		$16, 0($15)		                # 
    sw		$16, 0($14)		                # 0x3908 (so now phase1 is end)
    ori     $14,$0,0x3900
    ori     $15,$0,0x2f00                   # phase2: read the testcase in addr: 0x2f00+offset until readvalue == 0
    lw		$16, 0($15)		                # 
    #beq		$16, $0, gdb_end	            # if $16 == $0 then gdb_end
    nop    
    sw		$16, 0($14)		                # 0x3900
    jalr    $14				                # jump to $14 and save position to $ra
    nop                                     # now this addr is in $17(gdb addr) and another addr is in $15(testcase addr)

loop:
    j		loop				            # jump to loop
    nop

.org 0x2ef0
    nop
    jr		$ra					# jump to $ra
    ori     $17,$ra,0x0
.org 0x2f00
    sb		$2, 0x4000($0)		# 
    nop
    nop  
