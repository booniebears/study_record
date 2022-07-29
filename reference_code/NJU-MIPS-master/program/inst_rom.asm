
inst_rom.om:     file format elf32-tradbigmips


Disassembly of section .text:

00000000 <_start>:
       0:	ac005008 	sw	zero,20488(zero)
       4:	08000040 	j	100 <welcome>
       8:	341e7fff 	li	s8,0x7fff
	...

00000100 <welcome>:
     100:	0c00005c 	jal	170 <readthekeybroad>
     104:	3403000a 	li	v1,0xa
     108:	16e3fffd 	bne	s7,v1,100 <welcome>
     10c:	00000000 	nop
     110:	0c00006c 	jal	1b0 <clearmonitor>
     114:	00000000 	nop
     118:	34050000 	li	a1,0x0
     11c:	34060000 	li	a2,0x0
     120:	34070000 	li	a3,0x0
     124:	34080000 	li	t0,0x0
     128:	34090000 	li	t1,0x0
     12c:	340a0000 	li	t2,0x0
     130:	340b0000 	li	t3,0x0
     134:	340c0000 	li	t4,0x0
     138:	340d0000 	li	t5,0x0
     13c:	340e0000 	li	t6,0x0
     140:	340f0000 	li	t7,0x0
     144:	34100000 	li	s0,0x0
     148:	34110000 	li	s1,0x0
     14c:	34120000 	li	s2,0x0
     150:	34130000 	li	s3,0x0
     154:	34140000 	li	s4,0x0
     158:	34150000 	li	s5,0x0
     15c:	34160000 	li	s6,0x0
     160:	341a0000 	li	k0,0x0
     164:	341c0000 	li	gp,0x0
     168:	080000ce 	j	338 <mainloop>
     16c:	341d0004 	li	sp,0x4

00000170 <readthekeybroad>:
     170:	90175004 	lbu	s7,20484(zero)
     174:	12e00007 	beqz	s7,194 <readthekeybroad_noinput>
     178:	00000000 	nop
     17c:	90175000 	lbu	s7,20480(zero)
     180:	12e20008 	beq	s7,v0,1a4 <readthekeybroad_repeatinput>
     184:	00000000 	nop
     188:	36e20000 	ori	v0,s7,0x0
     18c:	03e00008 	jr	ra
     190:	00000000 	nop

00000194 <readthekeybroad_noinput>:
     194:	34170000 	li	s7,0x0
     198:	34020000 	li	v0,0x0
     19c:	03e00008 	jr	ra
     1a0:	00000000 	nop

000001a4 <readthekeybroad_repeatinput>:
     1a4:	34170000 	li	s7,0x0
     1a8:	03e00008 	jr	ra
     1ac:	00000000 	nop

000001b0 <clearmonitor>:
     1b0:	34034000 	li	v1,0x4000
     1b4:	34044834 	li	a0,0x4834

000001b8 <clearmonitor_loop>:
     1b8:	10640005 	beq	v1,a0,1d0 <clearmonitor_finish>
     1bc:	00000000 	nop
     1c0:	a0600000 	sb	zero,0(v1)
     1c4:	20630001 	addi	v1,v1,1
     1c8:	0800006e 	j	1b8 <clearmonitor_loop>
     1cc:	00000000 	nop

000001d0 <clearmonitor_finish>:
     1d0:	34180000 	li	t8,0x0
     1d4:	34190000 	li	t9,0x0
     1d8:	03e00008 	jr	ra
     1dc:	341b0000 	li	k1,0x0

000001e0 <printanasciicode>:
     1e0:	12e0004d 	beqz	s7,318 <printanasciicode_delete1end1>
     1e4:	00000000 	nop
     1e8:	3404001e 	li	a0,0x1e
     1ec:	1099004c 	beq	a0,t9,320 <printanasciicode_callclearmonitor>
     1f0:	afdf0000 	sw	ra,0(s8)

000001f4 <printanasciicode_aftercall>:
     1f4:	3403000a 	li	v1,0xa
     1f8:	1077000f 	beq	v1,s7,238 <printanasciicode_newline>
     1fc:	00000000 	nop
     200:	34030008 	li	v1,0x8
     204:	1077001a 	beq	v1,s7,270 <printanasciicode_delete>
     208:	00000000 	nop
     20c:	34040046 	li	a0,0x46
     210:	03240018 	mult	t9,a0
     214:	00001812 	mflo	v1
     218:	00781820 	add	v1,v1,t8
     21c:	a0774000 	sb	s7,16384(v1)
     220:	34050001 	li	a1,0x1
     224:	0305c020 	add	t8,t8,a1
     228:	1304000d 	beq	t8,a0,260 <printanasciicode_newline1>
     22c:	00000000 	nop
     230:	03e00008 	jr	ra
     234:	00000000 	nop

00000238 <printanasciicode_newline>:
     238:	341c0001 	li	gp,0x1
     23c:	34040046 	li	a0,0x46
     240:	03240018 	mult	t9,a0
     244:	00001812 	mflo	v1
     248:	00781820 	add	v1,v1,t8
     24c:	a0604000 	sb	zero,16384(v1)
     250:	34050001 	li	a1,0x1
     254:	0325c820 	add	t9,t9,a1
     258:	03e00008 	jr	ra
     25c:	34180000 	li	t8,0x0

00000260 <printanasciicode_newline1>:
     260:	34050001 	li	a1,0x1
     264:	0325c820 	add	t9,t9,a1
     268:	03e00008 	jr	ra
     26c:	34180000 	li	t8,0x0

00000270 <printanasciicode_delete>:
     270:	34040046 	li	a0,0x46
     274:	03240018 	mult	t9,a0
     278:	00001812 	mflo	v1
     27c:	00781820 	add	v1,v1,t8
     280:	a0604000 	sb	zero,16384(v1)
     284:	34050001 	li	a1,0x1
     288:	13000005 	beqz	t8,2a0 <printanasciicode_delete1>
     28c:	00000000 	nop
     290:	0305c022 	sub	t8,t8,a1
     294:	00651822 	sub	v1,v1,a1
     298:	03e00008 	jr	ra
     29c:	a0604000 	sb	zero,16384(v1)

000002a0 <printanasciicode_delete1>:
     2a0:	1320001d 	beqz	t9,318 <printanasciicode_delete1end1>
     2a4:	00000000 	nop
     2a8:	34050001 	li	a1,0x1
     2ac:	0325c822 	sub	t9,t9,a1
     2b0:	34180045 	li	t8,0x45
     2b4:	34040046 	li	a0,0x46
     2b8:	03240018 	mult	t9,a0
     2bc:	00001812 	mflo	v1
     2c0:	00781820 	add	v1,v1,t8
     2c4:	a0604000 	sb	zero,16384(v1)

000002c8 <printanasciicode_delete1loop>:
     2c8:	1300000c 	beqz	t8,2fc <printanasciicode_delete1end>
     2cc:	00000000 	nop
     2d0:	03240018 	mult	t9,a0
     2d4:	00001812 	mflo	v1
     2d8:	00781820 	add	v1,v1,t8
     2dc:	80664000 	lb	a2,16384(v1)
     2e0:	00000000 	nop
     2e4:	10c0fff8 	beqz	a2,2c8 <printanasciicode_delete1loop>
     2e8:	0305c023 	subu	t8,t8,a1
     2ec:	0305c021 	addu	t8,t8,a1
     2f0:	0305c021 	addu	t8,t8,a1
     2f4:	03e00008 	jr	ra
     2f8:	00000000 	nop

000002fc <printanasciicode_delete1end>:
     2fc:	03240018 	mult	t9,a0
     300:	00001812 	mflo	v1
     304:	80664000 	lb	a2,16384(v1)
     308:	00000000 	nop
     30c:	10c00002 	beqz	a2,318 <printanasciicode_delete1end1>
     310:	34180000 	li	t8,0x0
     314:	0305c021 	addu	t8,t8,a1

00000318 <printanasciicode_delete1end1>:
     318:	03e00008 	jr	ra
     31c:	00000000 	nop

00000320 <printanasciicode_callclearmonitor>:
     320:	0c00006c 	jal	1b0 <clearmonitor>
     324:	03ddf022 	sub	s8,s8,sp
     328:	03ddf020 	add	s8,s8,sp
     32c:	8fdf0000 	lw	ra,0(s8)
     330:	03e00008 	jr	ra
     334:	00000000 	nop

00000338 <mainloop>:
     338:	0c00005c 	jal	170 <readthekeybroad>
     33c:	00000000 	nop
     340:	0c000078 	jal	1e0 <printanasciicode>
     344:	00000000 	nop
     348:	101c0084 	beq	zero,gp,55c <mainloop_noenter>
     34c:	341c0000 	li	gp,0x0
     350:	34040046 	li	a0,0x46
     354:	009b0018 	mult	a0,k1
     358:	00001812 	mflo	v1
     35c:	80654000 	lb	a1,16384(v1)
     360:	3406002e 	li	a2,0x2e
     364:	14a60078 	bne	a1,a2,548 <mainloop_notorder>
     368:	34060001 	li	a2,0x1
     36c:	00661820 	add	v1,v1,a2
     370:	80654000 	lb	a1,16384(v1)
     374:	3406002f 	li	a2,0x2f
     378:	14a60073 	bne	a1,a2,548 <mainloop_notorder>
     37c:	00000000 	nop

00000380 <mainloop_ishello>:
     380:	34060001 	li	a2,0x1
     384:	00661820 	add	v1,v1,a2
     388:	80654000 	lb	a1,16384(v1)
     38c:	34060068 	li	a2,0x68
     390:	14a60023 	bne	a1,a2,420 <mainloop_isfib>
     394:	00000000 	nop
     398:	34060001 	li	a2,0x1
     39c:	00661820 	add	v1,v1,a2
     3a0:	80654000 	lb	a1,16384(v1)
     3a4:	34060065 	li	a2,0x65
     3a8:	14a60062 	bne	a1,a2,534 <mainloop_wrongorder>
     3ac:	00000000 	nop
     3b0:	34060001 	li	a2,0x1
     3b4:	00661820 	add	v1,v1,a2
     3b8:	80654000 	lb	a1,16384(v1)
     3bc:	3406006c 	li	a2,0x6c
     3c0:	14a6005c 	bne	a1,a2,534 <mainloop_wrongorder>
     3c4:	00000000 	nop
     3c8:	34060001 	li	a2,0x1
     3cc:	00661820 	add	v1,v1,a2
     3d0:	80654000 	lb	a1,16384(v1)
     3d4:	3406006c 	li	a2,0x6c
     3d8:	14a60056 	bne	a1,a2,534 <mainloop_wrongorder>
     3dc:	00000000 	nop
     3e0:	34060001 	li	a2,0x1
     3e4:	00661820 	add	v1,v1,a2
     3e8:	80654000 	lb	a1,16384(v1)
     3ec:	3406006f 	li	a2,0x6f
     3f0:	14a60050 	bne	a1,a2,534 <mainloop_wrongorder>
     3f4:	00000000 	nop
     3f8:	34060001 	li	a2,0x1
     3fc:	00661820 	add	v1,v1,a2
     400:	80654000 	lb	a1,16384(v1)
     404:	34060000 	li	a2,0x0
     408:	14a6004a 	bne	a1,a2,534 <mainloop_wrongorder>
     40c:	00000000 	nop
     410:	0c000165 	jal	594 <hello>
     414:	00000000 	nop
     418:	08000152 	j	548 <mainloop_notorder>
     41c:	00000000 	nop

00000420 <mainloop_isfib>:
     420:	34060066 	li	a2,0x66
     424:	14a60017 	bne	a1,a2,484 <mainloop_isgdb>
     428:	00000000 	nop
     42c:	34060001 	li	a2,0x1
     430:	00661820 	add	v1,v1,a2
     434:	80654000 	lb	a1,16384(v1)
     438:	34060069 	li	a2,0x69
     43c:	14a6003d 	bne	a1,a2,534 <mainloop_wrongorder>
     440:	00000000 	nop
     444:	34060001 	li	a2,0x1
     448:	00661820 	add	v1,v1,a2
     44c:	80654000 	lb	a1,16384(v1)
     450:	34060062 	li	a2,0x62
     454:	14a60037 	bne	a1,a2,534 <mainloop_wrongorder>
     458:	00000000 	nop
     45c:	34060001 	li	a2,0x1
     460:	00661820 	add	v1,v1,a2
     464:	80654000 	lb	a1,16384(v1)
     468:	34060000 	li	a2,0x0
     46c:	14a60031 	bne	a1,a2,534 <mainloop_wrongorder>
     470:	00000000 	nop
     474:	0c000186 	jal	618 <fib>
     478:	00000000 	nop
     47c:	08000152 	j	548 <mainloop_notorder>
     480:	00000000 	nop

00000484 <mainloop_isgdb>:
     484:	34060067 	li	a2,0x67
     488:	14a60017 	bne	a1,a2,4e8 <mainloop_ismu>
     48c:	00000000 	nop
     490:	34060001 	li	a2,0x1
     494:	00661820 	add	v1,v1,a2
     498:	80654000 	lb	a1,16384(v1)
     49c:	34060064 	li	a2,0x64
     4a0:	14a60024 	bne	a1,a2,534 <mainloop_wrongorder>
     4a4:	00000000 	nop
     4a8:	34060001 	li	a2,0x1
     4ac:	00661820 	add	v1,v1,a2
     4b0:	80654000 	lb	a1,16384(v1)
     4b4:	34060062 	li	a2,0x62
     4b8:	14a6001e 	bne	a1,a2,534 <mainloop_wrongorder>
     4bc:	00000000 	nop
     4c0:	34060001 	li	a2,0x1
     4c4:	00661820 	add	v1,v1,a2
     4c8:	80654000 	lb	a1,16384(v1)
     4cc:	34060000 	li	a2,0x0
     4d0:	14a60018 	bne	a1,a2,534 <mainloop_wrongorder>
     4d4:	00000000 	nop
     4d8:	0c0001d0 	jal	740 <gdb>
     4dc:	00000000 	nop
     4e0:	08000152 	j	548 <mainloop_notorder>
     4e4:	00000000 	nop

000004e8 <mainloop_ismu>:
     4e8:	3406006d 	li	a2,0x6d
     4ec:	14a60011 	bne	a1,a2,534 <mainloop_wrongorder>
     4f0:	00000000 	nop
     4f4:	34060001 	li	a2,0x1
     4f8:	00661820 	add	v1,v1,a2
     4fc:	80654000 	lb	a1,16384(v1)
     500:	34060075 	li	a2,0x75
     504:	14a6000b 	bne	a1,a2,534 <mainloop_wrongorder>
     508:	00000000 	nop
     50c:	34060001 	li	a2,0x1
     510:	00661820 	add	v1,v1,a2
     514:	80654000 	lb	a1,16384(v1)
     518:	34060000 	li	a2,0x0
     51c:	14a60005 	bne	a1,a2,534 <mainloop_wrongorder>
     520:	00000000 	nop
     524:	0c000159 	jal	564 <mu_>
     528:	00000000 	nop
     52c:	08000152 	j	548 <mainloop_notorder>
     530:	00000000 	nop

00000534 <mainloop_wrongorder>:
     534:	0c000078 	jal	1e0 <printanasciicode>
     538:	34170058 	li	s7,0x58
     53c:	0c000078 	jal	1e0 <printanasciicode>
     540:	3417000a 	li	s7,0xa
     544:	341c0000 	li	gp,0x0

00000548 <mainloop_notorder>:
     548:	373b0000 	ori	k1,t9,0x0
     54c:	3406001e 	li	a2,0x1e
     550:	17660002 	bne	k1,a2,55c <mainloop_noenter>
     554:	00000000 	nop
     558:	341b0000 	li	k1,0x0

0000055c <mainloop_noenter>:
     55c:	080000ce 	j	338 <mainloop>
     560:	00000000 	nop

00000564 <mu_>:
     564:	37e70000 	ori	a3,ra,0x0
     568:	341a0001 	li	k0,0x1
     56c:	ac1a5008 	sw	k0,20488(zero)
     570:	341a0008 	li	k0,0x8

00000574 <mu_loop>:
     574:	0c00005c 	jal	170 <readthekeybroad>
     578:	00000000 	nop
     57c:	1757fffd 	bne	k0,s7,574 <mu_loop>
     580:	00000000 	nop
     584:	ac005008 	sw	zero,20488(zero)
     588:	34ff0000 	ori	ra,a3,0x0
     58c:	03e00008 	jr	ra
     590:	00000000 	nop

00000594 <hello>:
     594:	37e70000 	ori	a3,ra,0x0
     598:	0c000078 	jal	1e0 <printanasciicode>
     59c:	34170068 	li	s7,0x68
     5a0:	0c000078 	jal	1e0 <printanasciicode>
     5a4:	34170065 	li	s7,0x65
     5a8:	0c000078 	jal	1e0 <printanasciicode>
     5ac:	3417006c 	li	s7,0x6c
     5b0:	0c000078 	jal	1e0 <printanasciicode>
     5b4:	3417006c 	li	s7,0x6c
     5b8:	0c000078 	jal	1e0 <printanasciicode>
     5bc:	3417006f 	li	s7,0x6f
     5c0:	0c000078 	jal	1e0 <printanasciicode>
     5c4:	34170020 	li	s7,0x20
     5c8:	0c000078 	jal	1e0 <printanasciicode>
     5cc:	34170077 	li	s7,0x77
     5d0:	0c000078 	jal	1e0 <printanasciicode>
     5d4:	3417006f 	li	s7,0x6f
     5d8:	0c000078 	jal	1e0 <printanasciicode>
     5dc:	34170072 	li	s7,0x72
     5e0:	0c000078 	jal	1e0 <printanasciicode>
     5e4:	3417006c 	li	s7,0x6c
     5e8:	0c000078 	jal	1e0 <printanasciicode>
     5ec:	34170064 	li	s7,0x64
     5f0:	0c000078 	jal	1e0 <printanasciicode>
     5f4:	3417000a 	li	s7,0xa
     5f8:	34ff0000 	ori	ra,a3,0x0
     5fc:	373b0000 	ori	k1,t9,0x0
     600:	3406001e 	li	a2,0x1e
     604:	17660002 	bne	k1,a2,610 <hello_ret>
     608:	00000000 	nop
     60c:	341b0000 	li	k1,0x0

00000610 <hello_ret>:
     610:	03e00008 	jr	ra
     614:	341c0000 	li	gp,0x0

00000618 <fib>:
     618:	37e70000 	ori	a3,ra,0x0
     61c:	34080000 	li	t0,0x0
     620:	3409000a 	li	t1,0xa

00000624 <fib_readinput>:
     624:	0c00005c 	jal	170 <readthekeybroad>
     628:	00000000 	nop
     62c:	0c000078 	jal	1e0 <printanasciicode>
     630:	00000000 	nop
     634:	1017fffb 	beq	zero,s7,624 <fib_readinput>
     638:	00000000 	nop
     63c:	141c0007 	bne	zero,gp,65c <fib_enterjudge>
     640:	00000000 	nop
     644:	3409000a 	li	t1,0xa
     648:	01090018 	mult	t0,t1
     64c:	00004012 	mflo	t0
     650:	34090030 	li	t1,0x30
     654:	02e9b822 	sub	s7,s7,t1
     658:	01174020 	add	t0,t0,s7

0000065c <fib_enterjudge>:
     65c:	101c0036 	beq	zero,gp,738 <fib_noenter>
     660:	00000000 	nop
     664:	34090000 	li	t1,0x0
     668:	340a0001 	li	t2,0x1
     66c:	340c0001 	li	t4,0x1

00000670 <fib_compute>:
     670:	11880006 	beq	t4,t0,68c <fib_printtheans>
     674:	00000000 	nop
     678:	354b0000 	ori	t3,t2,0x0
     67c:	01495020 	add	t2,t2,t1
     680:	35690000 	ori	t1,t3,0x0
     684:	0800019c 	j	670 <fib_compute>
     688:	218c0001 	addi	t4,t4,1

0000068c <fib_printtheans>:
     68c:	340c0000 	li	t4,0x0
     690:	37c90000 	ori	t1,s8,0x0
     694:	340d0004 	li	t5,0x4
     698:	012d4822 	sub	t1,t1,t5

0000069c <fib_printtheans1>:
     69c:	11400013 	beqz	t2,6ec <fib_printtheans2>
     6a0:	340d000a 	li	t5,0xa
     6a4:	218c0001 	addi	t4,t4,1
     6a8:	15a00002 	bnez	t5,6b4 <fib_printtheans1+0x18>
     6ac:	014d001a 	div	zero,t2,t5
     6b0:	0007000d 	break	0x7
     6b4:	2401ffff 	li	at,-1
     6b8:	15a10004 	bne	t5,at,6cc <fib_printtheans1+0x30>
     6bc:	3c018000 	lui	at,0x8000
     6c0:	15410002 	bne	t2,at,6cc <fib_printtheans1+0x30>
     6c4:	00000000 	nop
     6c8:	0006000d 	break	0x6
     6cc:	00005012 	mflo	t2
     6d0:	00005012 	mflo	t2
     6d4:	00005810 	mfhi	t3
     6d8:	ad2b0000 	sw	t3,0(t1)
     6dc:	340d0004 	li	t5,0x4
     6e0:	012d4822 	sub	t1,t1,t5
     6e4:	080001a7 	j	69c <fib_printtheans1>
     6e8:	00000000 	nop

000006ec <fib_printtheans2>:
     6ec:	11800008 	beqz	t4,710 <fib_printend>
     6f0:	340d0001 	li	t5,0x1
     6f4:	018d6022 	sub	t4,t4,t5
     6f8:	21290004 	addi	t1,t1,4
     6fc:	8d370000 	lw	s7,0(t1)
     700:	0c000078 	jal	1e0 <printanasciicode>
     704:	22f70030 	addi	s7,s7,48
     708:	080001bb 	j	6ec <fib_printtheans2>
     70c:	00000000 	nop

00000710 <fib_printend>:
     710:	0c000078 	jal	1e0 <printanasciicode>
     714:	3417000a 	li	s7,0xa
     718:	34ff0000 	ori	ra,a3,0x0
     71c:	373b0000 	ori	k1,t9,0x0
     720:	3406001e 	li	a2,0x1e
     724:	17660002 	bne	k1,a2,730 <fib_ret>
     728:	00000000 	nop
     72c:	341b0000 	li	k1,0x0

00000730 <fib_ret>:
     730:	03e00008 	jr	ra
     734:	341c0000 	li	gp,0x0

00000738 <fib_noenter>:
     738:	08000189 	j	624 <fib_readinput>
     73c:	341c0000 	li	gp,0x0

00000740 <gdb>:
     740:	37e70000 	ori	a3,ra,0x0
     744:	340e3904 	li	t6,0x3904
     748:	340f2ef0 	li	t7,0x2ef0
     74c:	8df00000 	lw	s0,0(t7)
     750:	add00000 	sw	s0,0(t6)
     754:	21ef0004 	addi	t7,t7,4
     758:	21ce0004 	addi	t6,t6,4
     75c:	8df00000 	lw	s0,0(t7)
     760:	add00000 	sw	s0,0(t6)
     764:	21ef0004 	addi	t7,t7,4
     768:	21ce0004 	addi	t6,t6,4
     76c:	8df00000 	lw	s0,0(t7)
     770:	add00000 	sw	s0,0(t6)
     774:	340e3904 	li	t6,0x3904
     778:	340f2f00 	li	t7,0x2f00

0000077c <gdb_phase2>:
     77c:	8df00000 	lw	s0,0(t7)
     780:	00000000 	nop
     784:	120000c9 	beqz	s0,aac <gdb_end>
     788:	00000000 	nop
     78c:	add00000 	sw	s0,0(t6)
     790:	340e3900 	li	t6,0x3900
     794:	01c0f809 	jalr	t6
     798:	00000000 	nop

0000079c <gdb_print1>:
     79c:	34120000 	li	s2,0x0
     7a0:	00000000 	nop
     7a4:	000f9702 	srl	s2,t7,0x1c
     7a8:	3252000f 	andi	s2,s2,0xf
     7ac:	3413000a 	li	s3,0xa
     7b0:	02539822 	sub	s3,s2,s3
     7b4:	06600002 	bltz	s3,7c0 <gdb_print10>
     7b8:	22520030 	addi	s2,s2,48
     7bc:	22520007 	addi	s2,s2,7

000007c0 <gdb_print10>:
     7c0:	0c000078 	jal	1e0 <printanasciicode>
     7c4:	36570000 	ori	s7,s2,0x0
     7c8:	34120000 	li	s2,0x0
     7cc:	00000000 	nop
     7d0:	000f9602 	srl	s2,t7,0x18
     7d4:	3252000f 	andi	s2,s2,0xf
     7d8:	3413000a 	li	s3,0xa
     7dc:	02539822 	sub	s3,s2,s3
     7e0:	06600002 	bltz	s3,7ec <gdb_print11>
     7e4:	22520030 	addi	s2,s2,48
     7e8:	22520007 	addi	s2,s2,7

000007ec <gdb_print11>:
     7ec:	0c000078 	jal	1e0 <printanasciicode>
     7f0:	36570000 	ori	s7,s2,0x0
     7f4:	34120000 	li	s2,0x0
     7f8:	00000000 	nop
     7fc:	000f9502 	srl	s2,t7,0x14
     800:	3252000f 	andi	s2,s2,0xf
     804:	3413000a 	li	s3,0xa
     808:	02539822 	sub	s3,s2,s3
     80c:	06600002 	bltz	s3,818 <gdb_print12>
     810:	22520030 	addi	s2,s2,48
     814:	22520007 	addi	s2,s2,7

00000818 <gdb_print12>:
     818:	0c000078 	jal	1e0 <printanasciicode>
     81c:	36570000 	ori	s7,s2,0x0
     820:	34120000 	li	s2,0x0
     824:	00000000 	nop
     828:	000f9402 	srl	s2,t7,0x10
     82c:	3252000f 	andi	s2,s2,0xf
     830:	3413000a 	li	s3,0xa
     834:	02539822 	sub	s3,s2,s3
     838:	06600002 	bltz	s3,844 <gdb_print13>
     83c:	22520030 	addi	s2,s2,48
     840:	22520007 	addi	s2,s2,7

00000844 <gdb_print13>:
     844:	0c000078 	jal	1e0 <printanasciicode>
     848:	36570000 	ori	s7,s2,0x0
     84c:	34120000 	li	s2,0x0
     850:	00000000 	nop
     854:	000f9302 	srl	s2,t7,0xc
     858:	3252000f 	andi	s2,s2,0xf
     85c:	3413000a 	li	s3,0xa
     860:	02539822 	sub	s3,s2,s3
     864:	06600002 	bltz	s3,870 <gdb_print14>
     868:	22520030 	addi	s2,s2,48
     86c:	22520007 	addi	s2,s2,7

00000870 <gdb_print14>:
     870:	0c000078 	jal	1e0 <printanasciicode>
     874:	36570000 	ori	s7,s2,0x0
     878:	34120000 	li	s2,0x0
     87c:	00000000 	nop
     880:	000f9202 	srl	s2,t7,0x8
     884:	3252000f 	andi	s2,s2,0xf
     888:	3413000a 	li	s3,0xa
     88c:	02539822 	sub	s3,s2,s3
     890:	06600002 	bltz	s3,89c <gdb_print15>
     894:	22520030 	addi	s2,s2,48
     898:	22520007 	addi	s2,s2,7

0000089c <gdb_print15>:
     89c:	0c000078 	jal	1e0 <printanasciicode>
     8a0:	36570000 	ori	s7,s2,0x0
     8a4:	34120000 	li	s2,0x0
     8a8:	00000000 	nop
     8ac:	000f9102 	srl	s2,t7,0x4
     8b0:	3252000f 	andi	s2,s2,0xf
     8b4:	3413000a 	li	s3,0xa
     8b8:	02539822 	sub	s3,s2,s3
     8bc:	06600002 	bltz	s3,8c8 <gdb_print16>
     8c0:	22520030 	addi	s2,s2,48
     8c4:	22520007 	addi	s2,s2,7

000008c8 <gdb_print16>:
     8c8:	0c000078 	jal	1e0 <printanasciicode>
     8cc:	36570000 	ori	s7,s2,0x0
     8d0:	34120000 	li	s2,0x0
     8d4:	00000000 	nop
     8d8:	000f9002 	srl	s2,t7,0x0
     8dc:	3252000f 	andi	s2,s2,0xf
     8e0:	3413000a 	li	s3,0xa
     8e4:	02539822 	sub	s3,s2,s3
     8e8:	06600002 	bltz	s3,8f4 <gdb_print17>
     8ec:	22520030 	addi	s2,s2,48
     8f0:	22520007 	addi	s2,s2,7

000008f4 <gdb_print17>:
     8f4:	0c000078 	jal	1e0 <printanasciicode>
     8f8:	36570000 	ori	s7,s2,0x0
     8fc:	0c000078 	jal	1e0 <printanasciicode>
     900:	3417000a 	li	s7,0xa
     904:	373b0000 	ori	k1,t9,0x0
     908:	3406001e 	li	a2,0x1e
     90c:	17660002 	bne	k1,a2,918 <gdb_phase22>
     910:	00000000 	nop
     914:	341b0000 	li	k1,0x0

00000918 <gdb_phase22>:
     918:	34120000 	li	s2,0x0
     91c:	00000000 	nop
     920:	00119702 	srl	s2,s1,0x1c
     924:	3252000f 	andi	s2,s2,0xf
     928:	3413000a 	li	s3,0xa
     92c:	02539822 	sub	s3,s2,s3
     930:	06600002 	bltz	s3,93c <gdb_print20>
     934:	22520030 	addi	s2,s2,48
     938:	22520007 	addi	s2,s2,7

0000093c <gdb_print20>:
     93c:	0c000078 	jal	1e0 <printanasciicode>
     940:	36570000 	ori	s7,s2,0x0
     944:	34120000 	li	s2,0x0
     948:	00000000 	nop
     94c:	00119602 	srl	s2,s1,0x18
     950:	3252000f 	andi	s2,s2,0xf
     954:	3413000a 	li	s3,0xa
     958:	02539822 	sub	s3,s2,s3
     95c:	06600002 	bltz	s3,968 <gdb_print21>
     960:	22520030 	addi	s2,s2,48
     964:	22520007 	addi	s2,s2,7

00000968 <gdb_print21>:
     968:	0c000078 	jal	1e0 <printanasciicode>
     96c:	36570000 	ori	s7,s2,0x0
     970:	34120000 	li	s2,0x0
     974:	00000000 	nop
     978:	00119502 	srl	s2,s1,0x14
     97c:	3252000f 	andi	s2,s2,0xf
     980:	3413000a 	li	s3,0xa
     984:	02539822 	sub	s3,s2,s3
     988:	06600002 	bltz	s3,994 <gdb_print22>
     98c:	22520030 	addi	s2,s2,48
     990:	22520007 	addi	s2,s2,7

00000994 <gdb_print22>:
     994:	0c000078 	jal	1e0 <printanasciicode>
     998:	36570000 	ori	s7,s2,0x0
     99c:	34120000 	li	s2,0x0
     9a0:	00000000 	nop
     9a4:	00119402 	srl	s2,s1,0x10
     9a8:	3252000f 	andi	s2,s2,0xf
     9ac:	3413000a 	li	s3,0xa
     9b0:	02539822 	sub	s3,s2,s3
     9b4:	06600002 	bltz	s3,9c0 <gdb_print23>
     9b8:	22520030 	addi	s2,s2,48
     9bc:	22520007 	addi	s2,s2,7

000009c0 <gdb_print23>:
     9c0:	0c000078 	jal	1e0 <printanasciicode>
     9c4:	36570000 	ori	s7,s2,0x0
     9c8:	34120000 	li	s2,0x0
     9cc:	00000000 	nop
     9d0:	00119302 	srl	s2,s1,0xc
     9d4:	3252000f 	andi	s2,s2,0xf
     9d8:	3413000a 	li	s3,0xa
     9dc:	02539822 	sub	s3,s2,s3
     9e0:	06600002 	bltz	s3,9ec <gdb_print24>
     9e4:	22520030 	addi	s2,s2,48
     9e8:	22520007 	addi	s2,s2,7

000009ec <gdb_print24>:
     9ec:	0c000078 	jal	1e0 <printanasciicode>
     9f0:	36570000 	ori	s7,s2,0x0
     9f4:	34120000 	li	s2,0x0
     9f8:	00000000 	nop
     9fc:	00119202 	srl	s2,s1,0x8
     a00:	3252000f 	andi	s2,s2,0xf
     a04:	3413000a 	li	s3,0xa
     a08:	02539822 	sub	s3,s2,s3
     a0c:	06600002 	bltz	s3,a18 <gdb_print25>
     a10:	22520030 	addi	s2,s2,48
     a14:	22520007 	addi	s2,s2,7

00000a18 <gdb_print25>:
     a18:	0c000078 	jal	1e0 <printanasciicode>
     a1c:	36570000 	ori	s7,s2,0x0
     a20:	34120000 	li	s2,0x0
     a24:	00000000 	nop
     a28:	00119102 	srl	s2,s1,0x4
     a2c:	3252000f 	andi	s2,s2,0xf
     a30:	3413000a 	li	s3,0xa
     a34:	02539822 	sub	s3,s2,s3
     a38:	06600002 	bltz	s3,a44 <gdb_print26>
     a3c:	22520030 	addi	s2,s2,48
     a40:	22520007 	addi	s2,s2,7

00000a44 <gdb_print26>:
     a44:	0c000078 	jal	1e0 <printanasciicode>
     a48:	36570000 	ori	s7,s2,0x0
     a4c:	34120000 	li	s2,0x0
     a50:	00000000 	nop
     a54:	00119002 	srl	s2,s1,0x0
     a58:	3252000f 	andi	s2,s2,0xf
     a5c:	3413000a 	li	s3,0xa
     a60:	02539822 	sub	s3,s2,s3
     a64:	06600002 	bltz	s3,a70 <gdb_print27>
     a68:	22520030 	addi	s2,s2,48
     a6c:	22520007 	addi	s2,s2,7

00000a70 <gdb_print27>:
     a70:	0c000078 	jal	1e0 <printanasciicode>
     a74:	36570000 	ori	s7,s2,0x0
     a78:	0c000078 	jal	1e0 <printanasciicode>
     a7c:	3417000a 	li	s7,0xa
     a80:	373b0000 	ori	k1,t9,0x0
     a84:	3406001e 	li	a2,0x1e
     a88:	17660002 	bne	k1,a2,a94 <gdb_loop>
     a8c:	21ef0004 	addi	t7,t7,4
     a90:	341b0000 	li	k1,0x0

00000a94 <gdb_loop>:
     a94:	0c00005c 	jal	170 <readthekeybroad>
     a98:	34140073 	li	s4,0x73
     a9c:	12f4ff37 	beq	s7,s4,77c <gdb_phase2>
     aa0:	00000000 	nop
     aa4:	080002a5 	j	a94 <gdb_loop>
     aa8:	00000000 	nop

00000aac <gdb_end>:
     aac:	0c000078 	jal	1e0 <printanasciicode>
     ab0:	34170045 	li	s7,0x45
     ab4:	0c000078 	jal	1e0 <printanasciicode>
     ab8:	3417004e 	li	s7,0x4e
     abc:	0c000078 	jal	1e0 <printanasciicode>
     ac0:	34170044 	li	s7,0x44
     ac4:	0c000078 	jal	1e0 <printanasciicode>
     ac8:	34170021 	li	s7,0x21
     acc:	0c000078 	jal	1e0 <printanasciicode>
     ad0:	3417000a 	li	s7,0xa
     ad4:	34ff0000 	ori	ra,a3,0x0
     ad8:	373b0000 	ori	k1,t9,0x0
     adc:	3406001e 	li	a2,0x1e
     ae0:	17660002 	bne	k1,a2,aec <gdb_ret>
     ae4:	00000000 	nop
     ae8:	341b0000 	li	k1,0x0

00000aec <gdb_ret>:
     aec:	03e00008 	jr	ra
     af0:	341c0000 	li	gp,0x0
	...
    2ef4:	03e00008 	jr	ra
    2ef8:	37f10000 	ori	s1,ra,0x0
    2efc:	00000000 	nop

00002f00 <gdb_target>:
    2f00:	34150048 	li	s5,0x48
    2f04:	34160078 	li	s6,0x78
    2f08:	02b6a820 	add	s5,s5,s6
    2f0c:	02b6a822 	sub	s5,s5,s6
    2f10:	00000000 	nop

Disassembly of section .reginfo:

00000000 <.reginfo>:
   0:	fffffffe 	sdc3	$31,-2(ra)
	...
