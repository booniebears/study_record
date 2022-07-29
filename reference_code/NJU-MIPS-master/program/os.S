# instruction area 0x0~0x2fff    GRAM area 0x3000~0x3833     KEYBROAD: 0x38fe ENABLE 0x38ff ASCIICODE
# RAM: begin at 0x3900 at least end after 0x4000
# $0===0 $24:column pointer(0~69) $25:line pointer(0~29) $31:return addr(caller's addr+0x08) $30: stack top $29 to modify the stack addr(always 4)
# $28 keybroad ENTER signal $27 unprocessed instrtion line pointer (0~29,begin at 0)
# $23: return data $2: last input ascii $3 $4 $5 $6: temp data  $7: save the old $31 in program ./hello ./fib & ./gdb
# $8: fib data input $9 $10 $11 $13: fib temp data $12: fib count register 
# $14 $15: gdb temp addr $16 $18 $19 $20: gdb temp data $17: gdb testcase retaddr $21 $22: testcase temp

# new mm_io rules:
# ROM 0x0000 0x3fff  GRAM 0x4000 0x4fff   asciicode 0x5000 asciienable 0x5004   RAM 0x6000 0x7fff

.org 0x0
#.set noat
.set noreorder
.set nomacro

.global _start
_start:
    sw		$0, 0x5008($0)		# close the enable of music
    j		welcome				# jump to welcome
    ori     $30,$0,0x7fff       # init the stack top addr

.org 0x100                              # may not enough...
welcome:
    jal		readthekeybroad				# jump to readthekeybroad and save position to $ra call readthekeybroad
    ori     $3,$0,0x0a
    bne		$23, $3, welcome	        # if $23 != $3 then welcome
    nop                                 # $3 is released from here
    jal		clearmonitor				# jump to clearmonitor and save position to $ra  call clearmonitor
    nop
    # ori     $1,$0,0x0
    # ori     $2,$0,0x0
    # ori     $3,$0,0x0
    # ori     $4,$0,0x0
    ori     $5,$0,0x0
    ori     $6,$0,0x0
    ori     $7,$0,0x0
    ori     $8,$0,0x0
    ori     $9,$0,0x0
    ori     $10,$0,0x0
    ori     $11,$0,0x0
    ori     $12,$0,0x0
    ori     $13,$0,0x0
    ori     $14,$0,0x0
    ori     $15,$0,0x0
    ori     $16,$0,0x0
    ori     $17,$0,0x0
    ori     $18,$0,0x0
    ori     $19,$0,0x0
    ori     $20,$0,0x0
    ori     $21,$0,0x0
    ori     $22,$0,0x0
    # ori     $23,$0,0x0
    # ori     $24,$0,0x0
    # ori     $25,$0,0x0
    ori     $26,$0,0x0
    # ori     $27,$0,0x0
    ori     $28,$0,0x0
    # ori     $29,$0,0x0
    # ori     $31,$0,0x0                  # clear the singal
    j		mainloop			    	# jump to mainloop
    ori     $29,$0,0x04

# ------------------------- function readthekeybroad ----------------------
readthekeybroad:
    lbu     $23,0x5004($0)
    beq		$23, $0, readthekeybroad_noinput	    # if $23 == $0 then readthekeybroad_noinput
    nop
    lbu     $23,0x5000($0)
    beq		$23, $2, readthekeybroad_repeatinput	# if $23 == $2 then readthekeybroad_repeatinput
    nop
    ori     $2,$23,0x0           # last input = return data (for next time use)
    jr		$ra					# jump to $ra
    nop
readthekeybroad_noinput:
    ori     $23,$0,0x0           # return 0
    ori     $2,$0,0x0           # clear the last input ascii
    jr		$ra     	    	# jump to $ra
    nop
readthekeybroad_repeatinput:
    ori     $23,$0,0x0           # return 0
    jr		$ra					# jump to $ra
    nop
# return veriable register: $23
# global register: $2
# ------------------------- function end ------------------------------------

# ------------------------- function clearmonitor ----------------------
clearmonitor:
    ori     $3,$0,0x4000
    ori     $4,$0,0x4834
clearmonitor_loop:
    beq		$3, $4, clearmonitor_finish 	# if $3 == $4 then clearmonitor_finish
    nop
    sb		$0, 0($3)		                # 
    addi	$3, $3, 0x01	    	    	# $3 = $3 + 0x01
    j		clearmonitor_loop				# jump to clearmonitor
    nop
clearmonitor_finish:
    ori     $24,$0,0x0          # init the column pointer & line pointer
    ori     $25,$0,0x0
    jr		$ra					# jump to $ra
    ori     $27,$0,0x0
# temp register: $3, $4
# ------------------------- function end ------------------------------------

# ------------------------- function printanasciicode ----------------------
# $24:column pointer(0~69) $25:line pointer(0~29) GRAM area 0x3000~0x3833
# load the code need to print in the register $23
# special case: 0x0a(\n) & 0x08(backspace)
# need to call the function clearthemonitor
# $3==offset,$4==70,$5==1,$6==the read data: temp veriable
# global veriable: $28: ENTER singal
printanasciicode:
    beq     $23,$0,printanasciicode_delete2             # if input is 0x0(noinput) then ret directly
    nop 
                                                        # ori     $4,$0,0x4
                                                        # sub		$30, $30, $4		     # $30 = $30 - $4
    ori     $4,$0,0x1e                                  # 0x1e = 30
    beq		$4, $25, printanasciicode_callclearmonitor	# if $4 == $25 then printanasciicode_callclearmonitor
    sw		$31, 0($30)	                            	# save the old esp (push esp)
printanasciicode_aftercall:
    ori     $3,$0,0x0a                          # case \n
    beq		$3, $23, printanasciicode_newline	# if $3 == $23 then printanasciicode_newline
    nop
    ori     $3,$0,0x08                          # case backspace
    beq		$3, $23, printanasciicode_delete	# if $3 == $23 then printanasciicode_delete
    nop                                         # not special case
    ori     $4,$0,0x46                          # 0x46 == 70
    mult	$25, $4		                    	# $25 * $4 = Hi and Lo registers
    mflo	$3				                   	# copy Lo to $3
    add		$3, $3, $24	                    	# $3 = $3 + $24
    sb		$23, 0x4000($3)		                # 
    ori     $5,$0,0x01                          # $5 = 1
    add		$24, $24, $5	                  	# $24 = $24 + $5
    beq		$24, $4, printanasciicode_newline1	# if $24 == $4 then printanasciicode_newline1
    nop
    jr		$ra					                # jump to $ra
    nop
printanasciicode_newline:                       # this newline's cause is input is \n (cover the corsor) (another important thing: send out a singal)
    ori     $28,$0,0x01                         # send out the ENTER singal (for caller know the enter is coimg)
    ori     $4,$0,0x46                          # 0x46 == 70
    mult	$25, $4		                    	# $25 * $4 = Hi and Lo registers
    mflo	$3				                   	# copy Lo to $3
    add		$3, $3, $24	                    	# $3 = $3 + $24
    sb		$0, 0x4000($3)		                # 
    ori     $5,$0,0x01                          # $5 = 1
    add		$25, $25, $5	                  	# $25 = $25 + $5
    jr		$ra					                # jump to $ra
    ori     $24,$0,0x0                          # $24 = 0
printanasciicode_newline1:                      # this newline's cause is this line is full
    ori     $5,$0,0x01                          # $5 = 1
    add		$25, $25, $5	                  	# $25 = $25 + $5 (1 <= $25 <= 30)
    jr		$ra					                # jump to $ra
    ori     $24,$0,0x0                          # $24 = 0
printanasciicode_delete:
    ori     $4,$0,0x46                          # 0x46 == 70
    mult	$25, $4		                    	# $25 * $4 = Hi and Lo registers
    mflo	$3				                   	# copy Lo to $3
    add		$3, $3, $24	                    	# $3 = $3 + $24
    sb		$0, 0x4000($3)		                # 
    ori     $5,$0,0x01                          # $5 = 1            (now the corsor has been covered) case1:$24==0 case2: $24!=0
    beq		$24, $0, printanasciicode_delete1	# if $24 == $0 then printanasciicode_delete1
    nop
    sub		$24, $24, $5                		# $24 = $24 - $5
    sub		$3, $3, $5		                    # $3 = $3 - $5
    jr		$ra					                # jump to $ra
    sb		$0, 0x4000($3)		                #     
printanasciicode_delete1:                       # this is case1, case2 is in seg printanasciicode_delete (new case: $24 = $25 = 0, in this condition, do nothing) we use $6 here
    beq		$25, $0, printanasciicode_delete2	# if $25 == $0 then printanasciicode_delete2
    nop
    ori     $5,$0,0x01                          # $5 = 1
    sub		$25, $25, $5                		# $25 = $25 - $5
    ori     $24,$0,0x45                         # 0x45 = 69
    ori     $4,$0,0x46                          # 0x46 == 70
    mult	$25, $4		                    	# $25 * $4 = Hi and Lo registers
    mflo	$3				                   	# copy Lo to $3
    add		$3, $3, $24	                    	# $3 = $3 + $24
    sb		$0, 0x4000($3)		                # make sure the last column will been cleared 
printanasciicode_delete1loop:
    beq		$24, $0, printanasciicode_delete1end	# if $24 == $0 then printanasciicode_delete1end
    nop
    mult	$25, $4		                    	    # $25 * $4 = Hi and Lo registers
    mflo	$3				                   	    # copy Lo to $3
    add		$3, $3, $24	                    	    # $3 = $3 + $24
    lb		$6, 0x4000($3)	                        # 
    nop
    beq		$6, $0, printanasciicode_delete1loop	# if $0 == $6 then printanasciicode_delete1loop (read an no-zero data)
    subu	$24, $24, $5		                    # $24 = $24 - $5
    addu    $24,$24,$5
    addu    $24,$24,$5
    jr		$ra					                    # jump to $ra
    nop
printanasciicode_delete1end:                        # not sure wheere $24 == 0 has a data?
    mult	$25, $4		                    	    # $25 * $4 = Hi and Lo registers
    mflo	$3				                   	    # copy Lo to $3
    lb		$6, 0x4000($3)	                        # 
    nop
    beq		$6, $0, printanasciicode_delete1end1	# if $6 == $0 then printanasciicode_deleteend1
    ori     $24,$0,0x0
    addu    $24,$24,$5
printanasciicode_delete1end1:
printanasciicode_delete2:                       # do nothing but ret
    jr		$ra					                # jump to $ra
    nop
printanasciicode_callclearmonitor:
    jal		clearmonitor				# jump to clearmonitor and save position to $ra, the function can init two pointers of cursor 
    sub		$30, $30, $29		        # $30 = $30 - $29(always 4)
    add		$30, $30, $29       		# $30 = $30 + $29
    lw		$31, 0($30)		            # recovery the olp esp
    jr		$ra					        # jump to $ra
    nop
                                        # ori     $4,$0,0x4
    # j		printanasciicode_aftercall  # jump to printanasciicode_aftercall
    # nop
# $3==offset,$4==70,$5==1,$6==the read data: temp veriable
# ------------------------- function end ------------------------------------
# $0===0 $24:column pointer(0~69) $25:line pointer(0~29) $31:return addr(caller's addr+0x08) $30: stack top $29 to modify the stack addr(always 4)

mainloop:                               # ENTER signal: $28  $27 unprocessed instrtion line pointer (0~29,begin at 0)
    jal		readthekeybroad				# jump to readthekeybroad and save position to $ra call readthekeybroad
    nop
    jal		printanasciicode			# jump to printanasciicode and save position to $ra
    nop
    beq		$0, $28, mainloop_noenter	# if $0 == $28 then mainloop_noenter (the order is not finish)
    ori     $28,$0,0x0
    ori     $4,$0,0x46
    mult	$4, $27			            # $4 * $27 = Hi and Lo registers
    mflo	$3					        # copy Lo to $3
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x2e
    bne		$5, $6, mainloop_notorder	# if $5 != $6 then mainloop_notorder
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x2f
    bne		$5, $6, mainloop_notorder	# if $5 != $6 then mainloop_notorder
    nop
mainloop_ishello:                       # target str: ./ 'hello' 0x68 0x65 0x6c 0x6c 0x6f 0x00...
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x68
    bne		$5, $6, mainloop_isfib	    # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x65
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x6c
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x6c
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x6f
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x00
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    jal		hello				        # jump to hello and save position to $ra
    nop
    j		mainloop_notorder			# jump to mainloop_notorder
    nop
mainloop_isfib:                         # target str: ./ 'fib' 0x66 0x69 0x62 0x00...
    ori     $6,$0,0x66
    bne		$5, $6, mainloop_isgdb	    # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x69
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x62
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x00
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    jal		fib				            # jump to fib
    nop
    j		mainloop_notorder			# jump to mainloop_notorder
    nop
mainloop_isgdb:                         # target str: ./ 'gdb' 0x67 0x64 0x62 0x00...
    ori     $6,$0,0x67
    bne		$5, $6, mainloop_ismu       # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x64
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x62
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x00
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    jal		gdb				            # jump to gdb
    nop
    j		mainloop_notorder			# jump to mainloop_notorder
    nop
mainloop_ismu:
    ori     $6,$0,0x6d
    bne		$5, $6, mainloop_wrongorder	# if $5 != $6 then mainloop_wrongorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x75
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    ori     $6,$0,0x01
    add		$3, $3, $6		            # $3 = $3 + $5
    lb		$5, 0x4000($3)		        # 
    ori     $6,$0,0x00
    bne		$5, $6, mainloop_wrongorder # if $5 != $6 then mainloop_notorder
    nop
    jal		mu_				            # jump to mu_ and save position to $ra
    nop
    j		mainloop_notorder			# jump to mainloop_notorder
    nop
mainloop_wrongorder:
    jal		printanasciicode			# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x58                 # \0x58: X
    jal		printanasciicode			# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x0a                 # \0x0a: \n (don't forget clear the singal)
    ori     $28,$0,0x0                  # clear the singal
mainloop_notorder:
    ori     $27,$25,0x0                 # $27 = new $25(if not order) (problem: $25==30?)
    ori     $6,$0,0x1e
    bne		$27, $6, mainloop_noenter	# if $27 != $6(30) then mainloop_noenter
    nop
    ori     $27,$0,0x0                  # if $27 == 30  then $27 = 0
mainloop_noenter:
    j		mainloop				    # jump to mainloop
    nop                                 # $2 have important use: the function readthekeybroad

# ------------------------- function mu_ ----------------------------------
# use reg $26
mu_:
    ori     $7,$31,0x0
    ori     $26,$0,0x1
    sw		$26, 0x5008($0)		            # open the enable
    ori     $26,$0,0x08                     # backspace
mu_loop:
    jal		readthekeybroad				    # jump to readthekeybroad and save position to $ra call readthekeybroad
    nop
    bne		$26, $23, mu_loop	            # if $26 == $23 then mu_loop
    nop
    sw		$0, 0x5008($0)		            # close the enable
    ori     $31,$7,0x0                      # read the old $ra
    jr		$ra					            # jump to $ra
    nop
# ------------------------- function end ----------------------------------


# ------------------------- function hello ----------------------------------
# user program: no system register
hello:
    #sw		$31, 0x0($30)		            # 
    ori     $7,$31,0x0
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x68                     # 0x68 h
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x65                     # 0x65 e
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x6c                     # 0x6c l
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x6c                     # 0x6c l
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x6f                     # 0x6f o
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x20                     # 0x20 (space)
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x77                     # 0x77 w
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x6f                     # 0x6f o
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x72                     # 0x72 r
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x6c                     # 0x6c l
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x64                     # 0x64 d
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x0a                     # 0x0a \n
    ori     $31,$7,0x0                      # read the old $ra
    ori     $27,$25,0x0                     # $27 = new $25(if not order) (problem: $25==30?)
    ori     $6,$0,0x1e
    bne		$27, $6, hello_ret	            # if $27 != $6(30) then return
    nop
    ori     $27,$0,0x0                      # if $27 == 30  then $27 = 0
hello_ret:
    jr		$ra					            # jump to $ra
    ori     $28,$0,0x0                      # clear the singal(do not forgrt!)
# ------------------------- function end ------------------------------------

# ------------------------- function fib ------------------------------------
fib:
    ori     $7,$31,0x0
    ori     $8,$0,0x0                       # data input
    ori     $9,$0,0xa                       # 0x0a = 10
    ori     $10,$0,0x0                       # data input
    ori     $11,$0,0x0                       # data input
    ori     $12,$0,0x0                       # data input
    ori     $13,$0,0x0                       # data input
fib_readinput:
    jal		readthekeybroad				    # jump to readthekeybroad and save position to $ra call readthekeybroad
    nop
    jal		printanasciicode			    # jump to printanasciicode and save position to $ra  this module enable the ENTER signal
    nop
    beq		$0, $23, fib_readinput	        # if $0 != $23 then fib_readinput
    nop
    bne     $0, $28, fib_enterjudge
    nop 
    ori     $9,$0,0xa                       # 0x0a = 10
    mult	$8, $9			                # $8 * $9 = Hi and Lo registers
    mflo	$8					            # copy Lo to $8
    ori     $9,$0,0x30                      # 0x0a = 10
    sub		$23, $23, $9		            # $23 = $23 - $9
    add		$8, $8, $23		                # $8 = $8 + $23    
fib_enterjudge:
    beq		$0, $28, fib_noenter	        # if $0 == $28 then mainloop_noenter (the order is not finish)
    nop                                     # else means the data has been inputed, we need to compute now
    ori     $9,$0,0x00                      # init the registers
    ori     $10,$0,0x01
    ori     $12,$0,0x01
fib_compute:                                # now the input is in register: $8
    beq		$12, $8, fib_printtheans	    # if $12 == $8 then fib_printtheans
    nop
    ori     $11,$10,0x0
    add		$10, $10, $9		            # $10 = $10 + $9
    ori     $9,$11,0x0
    j		fib_compute				        # jump to fib_compute
    addi	$12, $12, 0x01			        # $12 = $12 + 0x01
fib_printtheans:                            # after comput, $10 saved the ans($9 $11 free now)
    ori     $12,$0,0x0                      # still the counter($12)
    ori     $9,$30,0x0
    ori     $13,$0,0x4
    sub		$9, $9, $13		                # $9 = $9 - $13(4)
fib_printtheans1:
    beq		$10, $0, fib_printtheans2	    # if $10 == $0 then fib_printtheans2
    ori     $13,$0,0xa                      # $13 === 10(0xa)
    addi	$12, $12, 0x01			        # $12 = $12 + 0x01
    div		$10, $13			            # $10 / $13
    mflo	$10					            # $10 = floor($10 / $13) 
    mfhi	$11					            # $11 = $10 mod $13 
    sw		$11, 0($9)		                # 
    ori     $13,$0,0x4
    sub		$9, $9, $13		                # $9 = $9 - $13(4)
    j		fib_printtheans1				# jump to fib_printtheans1
    nop
fib_printtheans2:
    beq		$12, $0, fib_printend	        # if $10 == $0 then fib_printend
    ori     $13,$0,0x1                      # $13 === 1 here
    sub		$12, $12, $13		            # $12 = $12 - $13
    addi	$9, $9, 0x04			        # $9 = $9 + 0x04
    lw		$23, 0($9)		                # 
    jal		printanasciicode                # jump to printanasciicode and save position to $ra
    addi    $23,$23,0x30                    # turn value to ascii code
    j		fib_printtheans2				# jump to fib_printtheans2
    nop
fib_printend:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x0a                     # 0x0a \n
    ori     $31,$7,0x0                      # read the old $ra
    ori     $27,$25,0x0                     # $27 = new $25(if not order) (problem: $25==30?)
    ori     $6,$0,0x1e
    bne		$27, $6, fib_ret	            # if $27 != $6(30) then return
    nop
    ori     $27,$0,0x0                      # if $27 == 30  then $27 = 0
fib_ret:
    jr		$ra					            # jump to $ra
    ori     $28,$0,0x0                      # clear the singal(do not forgrt!)
fib_noenter:
    j		fib_readinput				    # jump to fib_readinput
    ori     $28,$0,0x0                      # clear the singal
# ------------------------- function end ------------------------------------


# ------------------------- function gdb ------------------------------------
# $14 $15: gdb temp addr $16 $18 $19 $20: gdb temp data $17: gdb testcase retaddr $21 $22: testcase temp
# RAM: begin at 0x3900 at least end after 0x4000
gdb:                                        # phase1: load the order to 0x3900 0x3904 0x3908
    ori     $7,$31,0x0
    ori     $14,$0,0x3904
    ori     $15,$0,0x2ef0
    lw		$16, 0($15)		                # 
    sw		$16, 0($14)		                # 0x3900
    addi	$15, $15, 0x04			        # $15 = $15 + 0x04
    addi	$14, $14, 0x04			        # $15 = $15 + 0x04
    lw		$16, 0($15)		                # 
    sw		$16, 0($14)		                # 0x3904
    addi	$15, $15, 0x04			        # $15 = $15 + 0x04
    addi	$14, $14, 0x04			        # $15 = $15 + 0x04
    lw		$16, 0($15)		                # 
    sw		$16, 0($14)		                # 0x3908 (so now phase1 is end)
    ori     $14,$0,0x3904
    ori     $15,$0,0x2f00                   # phase2: read the testcase in addr: 0x2f00+offset until readvalue == 0
gdb_phase2:
    lw		$16, 0($15)		                # 
    nop
    beq		$16, $0, gdb_end	            # if $16 == $0 then gdb_end
    nop    
    sw		$16, 0($14)		                # 0x3900
    ori     $14,$0,0x3900
    jalr    $14				                # jump to $14 and save position to $ra
    nop                                     # now this addr is in $17(gdb addr) and another addr is in $15(testcase addr)
gdb_print1:                                 # print $15
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x1c                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print10
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print10:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x18                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print11
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print11:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x14                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print12
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print12:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x10                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print13
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print13:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x0c                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print14
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print14:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x08                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print15
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print15:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x04                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print16
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print16:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$15,0x00                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print17
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print17:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    jal     printanasciicode
    ori     $23,$0,0x0a                      # print \n
    ori     $27,$25,0x0                     # $27 = new $25(if not order) (problem: $25==30?)
    ori     $6,$0,0x1e
    bne		$27, $6, gdb_phase22	        # if $27 != $6(30) then return
    nop
    ori     $27,$0,0x0                      # if $27 == 30  then $27 = 0
gdb_phase22:                                # print $17
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x1c                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print20
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print20:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x18                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print21
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print21:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x14                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print22
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print22:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x10                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print23
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print23:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x0c                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print24
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print24:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x08                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print25
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print25:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x04                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print26
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print26:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    ori     $18,$0,0x0
    nop
    srl     $18,$17,0x00                    # print $15 first
    andi    $18,$18,0x0f
    ori     $19,$0,0xa
    sub		$19, $18, $19		            # $19 = $18 - $19 ($18: 0~9 $19<0)
    bltz    $19, gdb_print27
    addi	$18, $18, 0x30			        # $18 = $18 + 0x30
    addi	$18, $18, 0x07			        # $18 = $18 + 0x07
gdb_print27:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$18,0x0
    jal     printanasciicode
    ori     $23,$0,0x0a                     # print \n
    ori     $27,$25,0x0                     # $27 = new $25(if not order) (problem: $25==30?)
    ori     $6,$0,0x1e
    bne		$27, $6, gdb_loop   	        # if $27 != $6(30) then return
    addi	$15, $15, 0x04			        # $15 = $15 + 0x04
    ori     $27,$0,0x0                      # if $27 == 30  then $27 = 0
gdb_loop:
    jal		readthekeybroad				    # jump to readthekeybroad and save position to $ra
    ori     $20,$0,0x73                     # 0x73: asciicode of 's'
    beq		$23, $20, gdb_phase2	        # if $1 == $20 then gdb_phase2
    nop
    j		gdb_loop				        # jump to gdb_loop
    nop
gdb_end:
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x45
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x4e
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x44
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x21
    jal		printanasciicode				# jump to printanasciicode and save position to $ra
    ori     $23,$0,0x0a
    ori     $31,$7,0x0                      # read the old $ra
    ori     $27,$25,0x0                     # $27 = new $25(if not order) (problem: $25==30?)
    ori     $6,$0,0x1e
    bne		$27, $6, gdb_ret	            # if $27 != $6(30) then return
    nop
    ori     $27,$0,0x0                      # if $27 == 30  then $27 = 0
gdb_ret:
    jr		$ra					            # jump to $ra
    ori     $28,$0,0x0                      # clear the singal(do not forgrt! even useless)
# ------------------------- function end ------------------------------------

# ------------------------- gdb targettestcase ------------------------------
.org 0x2ef0
    nop
    jr		$ra					# jump to $ra
    ori     $17,$ra,0x0
.org 0x2f00
# end is 0x2ffc max 96
gdb_target:
    ori     $21,$0,0x48
    ori     $22,$0,0x78
    add		$21, $21, $22		# $21 = $21 + $22
    sub		$21, $21, $22		# $21 = $21 - $22
    # mult	$21, $22			# $21 * $22 = Hi and Lo registers
    # mflo	$21					# copy Lo to $21
    # div		$21, $22			# $21 / $22
    # mflo	$21					# $21 = floor($21 / $22) 
    # mfhi	$22					# $22 = $21 mod $22 
    nop
# ------------------------- end -------------------------------------------


