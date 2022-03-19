.nlist
; ****************************************************************************
; 
; Include This File To Define The AT89LP51RB2/RC2/RD2/ED2/IC2/ID2 SFRs
; 
; 	!!! NOTE !!!
; 		Only SFR Registers And
; 		Bit Addressable Register Bits Are Defined
; 
; ****************************************************************************
; 
	; Set UPPER_CASE_SFR Non Zero To Define Upper Case SFRs
	; Set LOWER_CASE_SFR Non Zero To Define Lower Case SFRs
	; Else Both Upper And Lower Case SFRs Will Be Defined

	.ifeq	UPPER_CASE_SFR + LOWER_CASE_SFR
		UPPER_CASE_SFR = 1
		LOWER_CASE_SFR = 1
	.endif

; 
; ****************************************************************************
; 
	; Macro To Define Bit Addressable SFRs By Bit Number
        ; Creates Symbols str.0 = addr+0, str.1 = addr+1, ... , str.7 = addr+7
	.macro	.sfr.n	addr, str
	  .ifnb	str
	    .irpc c ^/01234567/
	str'.'c =: addr + c
	    .endm
	  .endif
	.endm

; 
; ****************************************************************************
; 
	; Macro To Define SFR Bit Names
	; Creates Symbols str0 = addr+0, str1 = addr+1, ..., str7 = addr+7
	.macro	.sfr.b	addr, str0, str1, str2, str3, str4, str5, str6, str7
	  sfr$n =: 0
	  .irp	str, str0, str1, str2, str3, str4, str5, str6, str7
	    .ifnb str
	str =: addr + sfr$n
	    .endif
	    sfr$n = sfr$n + 1
	  .endm
	.endm

; 
; ****************************************************************************
; 
	; Macro To Define SFRs By Register Names
	; Creates Symbols str0 = addr+0, str1 = addr+1, ..., str7 = addr+7
	.macro	.sfr.r	addr, str0, str1, str2, str3, str4, str5, str6, str7
	  sfr$n =: 0
	  .ifndef sfr$'addr
	    sfr$'addr =: 0
	  .endif
	  .irp	str, str0, str1, str2, str3, str4, str5, str6, str7
	    .ifnb str
	str =: addr + sfr$n
	sfr$'addr = sfr$'addr | (1 << sfr$n)
	    .endif
	    sfr$n = sfr$n + 1
	  .endm
	.endm

; 
; ****************************************************************************

.ifne	UPPER_CASE_SFR
	.list	(!,src)
; 	AT89LP51RD2/ED2/ID2 Upper Case SFRs     Defined
; 	AT89LP51RB2/RC2/IC2 Upper Case SFRs     Defined
.nlist

.sfr.n	0x80,	P0
.sfr.n	0x80,	AD
.sfr.n	0x80,	ADC
.sfr.r	0x80,	P0,	SP,	DP0L,	DP0H,	,	CKSEL,	OSCCON,	PCON
.sfr.r	0x80,	,	,	DPL,	DPH	,	,	,
.sfr.r	0x80,	,	,	DPTRL,	DPTRH	,	,	,
.sfr.r	0x80,	AD,	,	,	,	,	,	,
.sfr.r	0x80,	ADC,	,	,	,	,	,	,

.sfr.n	0x88,	TCON
.sfr.b	0x88,	IT0,	IE0,	IT1,	IE1,	TR0,	TF0,	TR1,	TF1
.sfr.r	0x88,	TCON,	TMOD,	TL0,	TL1,	TH0,	TH1,	AUXR,	CKCON0

.sfr.n	0x90	P1
.sfr.b	0x90	GPI0,	GPI1,	GPI2,	GPI3,	GPI4,	GPI5,	GPI6,	GPI7
.sfr.b	0x90	T2,	T2EX,	EC1,	CEX0,	CEX2,	CEX2,	CEX3,	CEX4
.sfr.b	0x90	XTAL1B,	,	,	,	,	,	,
.sfr.b	0x90	,	SS$,	,	,	,	MISO,	SCK,	MOSI
.sfr.b	0x90	,	,	,	,	RSS$,	RMOSI,	RMISO,	RSCK
.sfr.r	0x90	P1,	TCONB,	BMSEL,	SSCON,	SSCS,	SSDAT,	SSADR,	CKRL

.sfr.n	0x98,	SCON
.sfr.b	0x98,	RI,	TI,	RB8,	TB8,	REN,	SM2,	SM1,	SM0
.sfr.b	0x98,	,	,	,	,	,	,	,	FE
.sfr.r	0x98,	SCON,	SBUF,	BRL,	BDRCON,	KBLS,	KBE,	KBF,	KBMOD

.sfr.n	0xA0,	P2
.sfr.b	0xA0,	,	,    DAPLUS,DAMINUS,	AIN0,	AIN1,	AIN2,	AIN3
.sfr.r	0xA0,	P2,	DPCF,	AUXR1,	ACSRA,	DADC,	DADI,	WDTRST,	WDTPRG

.sfr.n	0xA8,	IEN0
.sfr.b	0xA8,	EX0,	ET0,	EX1,	ET1,	ES,	ET2,	EC,	EA
.sfr.r	0xA8	IEN0,	SADDR,	,	ACSRB,	DADL,	DADH,	CLKREG,	CKCON1

.sfr.n	0xB0	P3
.sfr.b	0xB0	RXD,	TXD,	INT0$,	INT1$,	T0,	T1,	WR$,	RD$
.sfr.r	0xB0	P3,	IEN1,	IPL1,	IPH1,	,	,	,	IPH0

.sfr.n	0xB8	IPL0
.sfr.b	0xB8	PX0L,	PT0L,	PX1L,	PT1L,	PLS,	PT2L,	PPCL,	IP0DIS
.sfr.r	0xB8	IPL0,	SADEN,	,	,	,	AREF,	P4M0,	P4M1

.sfr.n	0xC0	P4
.sfr.b	0xC0	SCL,	SDA,	XTAL2B,	,	ALE,	PSEN$,	XTAL1A,	XTAL2A
.sfr.r	0xC0	P4,	,	,	SPCON,	SPSTA,	SPDAT,	P3M0,	P3M1

.sfr.n	0xC8	T2CON
.sfr.b	0xC8	CPRL2,	CT2,	TR2,	EXEN2,	TCLK,	RCLK,	EXF2,	TF2
.sfr.r	0xC8	T2CON,	T2MOD,	RCAP2L,	RCAP2H,	TL2,	TH2,	P2M0,	P2M1

.sfr.n	0xD0,	PSW
.sfr.b	0xD0,	P,	F1,	OV,	RS0,	RS1,	F0,	AC,	CY
.sfr.r	0xD0,	PSW,	FCON,	EECON,	,	DPLB,	DPHB,	P1M0,	P1M1

.sfr.n	0xD8,	CCON
.sfr.b	0xD8,	CCF0,	CCF1,	CCF2,	CCF3,	CCF4,	,	CR,	CF
.sfr.r	0xD8,	CCON,	CMOD,	CCAPM0,	CCAPM1,	CCAPM2,	CCAPM3,	CCAPM4,

.sfr.n	0xE0,	A
.sfr.n	0xE0,	ACC
.sfr.r	0xE0,	ACC,	AX,	DSPR,	FIRD,	MACL,	MACH,	P0M0,	P0M1

.sfr.n	0xE8,
.sfr.b	0xE8,	ENH,	DISSO,	SSIG,	,	,	LDEN,	WCOL,	SPIF
.sfr.r	0xE8,	,	CL,	CCAP0L,	CCAP1L,	CCAP2L,	CCAP3L,	CCAP4L,	SPX

.sfr.n	0xF0,	B
.sfr.r	0xF0,	B,	,	RL0,	RL1,	RH0,	RH1,	PAGE,	BX

.sfr.n	0xF8,
.sfr.r	0xF8,	,	CH,	CCAP0H,	CCAP1H,	CCAP2H,	CCAP3H,	CCAP4H,

; 
; 	The macro .sfr.r also creates the definition sfr$'addr
; 	that has a bit set for each SFR that is defined.  After
; 	processing the complete SFR table there will be 16
; 	definitions:
; 
; 	sfr$0x80	sfr$0x88	sfr$0x90	sfr$0x98
; 	sfr$0xA0	sfr$0xA8	sfr$0xB0	sfr$0xB8
; 	sfr$0xC0	sfr$0xC8	sfr$0xD0	sfr$0xD8
; 	sfr$0xE0	sfr$0xE8	sfr$0xF0	sfr$0xF8
; 

.endif

.ifne	LOWER_CASE_SFR
	.list	(!,src)
; 	AT89LP51RD2/ED2/ID2 Lower Case SFRs     Defined
; 	AT89LP51RB2/RC2/IC2 Lower Case SFRs     Defined
	.nlist

.sfr.n	0x80,	p0
.sfr.n	0x80,	ad
.sfr.n	0x80,	adc
.sfr.r	0x80,	p0,	sp,	dp0l,	dp0h,	,	cksel,	osccon,	pcon
.sfr.r	0x80,	,	,	dpl,	dph	,	,	,
.sfr.r	0x80,	,	,	dptrl,	dptrh	,	,	,
.sfr.r	0x80,	ad,	,	,	,	,	,	,
.sfr.r	0x80,	adc,	,	,	,	,	,	,

.sfr.n	0x88,	tcon
.sfr.b	0x88,	it0,	ie0,	it1,	ie1,	tr0,	tf0,	tr1,	tf1
.sfr.r	0x88,	tcon,	tmod,	tl0,	tl1,	th0,	th1,	auxr,	ckcon0

.sfr.n	0x90	p1
.sfr.b	0x90	gpi0,	gpi1,	gpi2,	gpi3,	gpi4,	gpi5,	gpi6,	gpi7
.sfr.b	0x90	t2,	t2ex,	ec1,	cex0,	cex2,	cex2,	cex3,	cex4
.sfr.b	0x90	xtal1b,	,	,	,	,	,	,
.sfr.b	0x90	,	ss$,	,	,	,	miso,	sck,	mosi
.sfr.b	0x90	,	,	,	,	rss$,	rmosi,	rmiso,	rsck
.sfr.r	0x90	p1,	tconb,	bmsel,	sscon,	sscs,	ssdat,	ssadr,	ckrl

.sfr.n	0x98,	scon
.sfr.b	0x98,	ri,	ti,	rb8,	tb8,	ren,	sm2,	sm1,	sm0
.sfr.b	0x98,	,	,	,	,	,	,	,	fe
.sfr.r	0x98,	scon,	sbuf,	brl,	bdrcon,	kbls,	kbe,	kbf,	kbmod

.sfr.n	0xa0,	p2
.sfr.b	0xa0,	,	,    daplus,daminus,	ain0,	ain1,	ain2,	ain3
.sfr.r	0xa0,	p2,	dpcf,	auxr1,	acsra,	dadc,	dadi,	wdtrst,	wdtprg

.sfr.n	0xa8,	ien0
.sfr.b	0xa8,	ex0,	et0,	ex1,	et1,	es,	et2,	ec,	ea
.sfr.r	0xa8	ien0,	saddr,	,	acsrb,	dadl,	dadh,	clkreg,	ckcon1

.sfr.n	0xb0	p3
.sfr.b	0xb0	rxd,	txd,	int0$,	int1$,	t0,	t1,	wr$,	rd$
.sfr.r	0xb0	p3,	ien1,	ipl1,	iph1,	,	,	,	iph0

.sfr.n	0xb8	ipl0
.sfr.b	0xb8	px0l,	pt0l,	px1l,	pt1l,	pls,	pt2l,	ppcl,	ip0dis
.sfr.r	0xb8	ipl0,	saden,	,	,	,	aref,	p4m0,	p4m1

.sfr.n	0xc0	p4
.sfr.b	0xc0	scl,	sda,	xtal2b,	,	ale,	psen$,	xtal1a,	xtal2a
.sfr.r	0xc0	p4,	,	,	spcon,	spsta,	spdat,	p3m0,	p3m1

.sfr.n	0xc8	t2con
.sfr.b	0xc8	cprl2,	ct2,	tr2,	exen2,	tclk,	rclk,	exf2,	tf2
.sfr.r	0xc8	t2con,	t2mod,	rcap2l,	rcap2h,	tl2,	th2,	p2m0,	p2m1

.sfr.n	0xd0,	psw
.sfr.b	0xd0,	p,	f1,	ov,	rs0,	rs1,	f0,	ac,	cy
.sfr.r	0xd0,	psw,	fcon,	eecon,	,	dplb,	dphb,	p1m0,	p1m1

.sfr.n	0xd8,	ccon
.sfr.b	0xd8,	ccf0,	ccf1,	ccf2,	ccf3,	ccf4,	,	cr,	cf
.sfr.r	0xd8,	ccon,	cmod,	ccapm0,	ccapm1,	ccapm2,	ccapm3,	ccapm4,

.sfr.n	0xe0,	a
.sfr.n	0xe0,	acc
.sfr.r	0xe0,	acc,	ax,	dspr,	fird,	macl,	mach,	p0m0,	p0m1

.sfr.n	0xe8,
.sfr.b	0xe8,	enh,	disso,	ssig,	,	,	lden,	wcol,	spif
.sfr.r	0xe8,	,	cl,	ccap0l,	ccap1l,	ccap2l,	ccap3l,	ccap4l,	spx

.sfr.n	0xf0,	b
.sfr.r	0xf0,	b,	,	rl0,	rl1,	rh0,	rh1,	page,	bx

.sfr.n	0xf8,
.sfr.r	0xf8,	,	ch,	ccap0h,	ccap1h,	ccap2h,	ccap3h,	ccap4h,

; 
; 	The macro .sfr.r also creates the definition sfr$'addr
; 	that has a bit set for each SFR that is defined.  After
; 	processing the complete SFR table there will be 16
; 	definitions:
; 
; 	sfr$0x80	sfr$0x88	sfr$0x90	sfr$0x98
; 	sfr$0xa0	sfr$0xa8	sfr$0xb0	sfr$0xb8
; 	sfr$0xc0	sfr$0xc8	sfr$0xd0	sfr$0xd8
; 	sfr$0xe0	sfr$0xe8	sfr$0xf0	sfr$0xf8
; 

.endif

