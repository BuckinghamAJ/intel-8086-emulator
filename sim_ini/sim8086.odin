package ini

Bits_Type :: enum u8 {
	None,
	Literal,
	D,
	S,
	W,
	V,
	Z,
	MOD,
	REG,
	RM,
	SR,
	Data,
	Disp,
	DispAlwaysW,
	WMakesDataW,
	RMRegAlwaysW,
	RelJMPDisp,
	Far,
}

Op :: enum u8 {
	none,
	mov,
	push,
	pop,
	xchg,
	in_,
	out_,
	xlat,
	lea,
	lds,
	les,
	lahf,
	sahf,
	pushf,
	popf,
	add,
	adc,
	inc,
	aaa,
	daa,
	sub,
	sbb,
	dec,
	neg,
	cmp,
	aas,
	das,
	mul,
	imul,
	aam,
	div,
	idiv,
	aad,
	cbw,
	cwd,
	not_,
	shl,
	shr,
	sar,
	rol,
	ror,
	rcl,
	rcr,
	and_,
	test,
	or_,
	xor_,
	rep,
	movs,
	cmps,
	scas,
	lods,
	stos,
	call,
	jmp,
	ret,
	retf,
	je,
	jl,
	jle,
	jb,
	jbe,
	jp,
	jo,
	js,
	jne,
	jnl,
	jg,
	jnb,
	ja,
	jnp,
	jno,
	jns,
	loop,
	loopz,
	loopnz,
	jcxz,
	int_,
	int3,
	into,
	iret,
	clc,
	cmc,
	stc,
	cld,
	std,
	cli,
	sti,
	hlt,
	wait_,
	esc,
	lock,
	segment,
}

Bit_Field :: struct {
	type:  Bits_Type,
	size:  u8, // bits to read from stream; 0 = implicit
	shift: u8,
	value: u8,
}

MAX_FIELDS :: 8

Instruction_Encoding :: struct {
	op:     Op,
	fields: [MAX_FIELDS]Bit_Field,
	count:  u8,
}

@(private)
B :: #force_inline proc(bits: u8, bit_count: u8) -> Bit_Field {
	return {.Literal, bit_count, 0, bits}
}

@(private)
Imp :: #force_inline proc(type: Bits_Type, value: u8) -> Bit_Field {
	return {type, 0, 0, value}
}

enc :: proc(op: Op, fields: ..Bit_Field) -> Instruction_Encoding {
	e := Instruction_Encoding {
		op = op,
	}
	for f, i in fields {
		e.fields[i] = f
		e.count += 1
	}
	return e
}

D :: Bit_Field{.D, 1, 0, 0}
S :: Bit_Field{.S, 1, 0, 0}
W :: Bit_Field{.W, 1, 0, 0}
V :: Bit_Field{.V, 1, 0, 0}
Z :: Bit_Field{.Z, 1, 0, 0}
MOD :: Bit_Field{.MOD, 2, 0, 0}
REG :: Bit_Field{.REG, 3, 0, 0}
RM :: Bit_Field{.RM, 3, 0, 0}
SR :: Bit_Field{.SR, 2, 0, 0}
XXX :: Bit_Field{.Data, 3, 0, 0}
YYY :: Bit_Field{.Data, 3, 3, 0}
DISP :: Bit_Field{.Disp, 0, 0, 0}
DATA :: Bit_Field{.Data, 0, 0, 0}
DATA_IF_W :: Bit_Field{.WMakesDataW, 0, 0, 1}
ADDR_0 :: Bit_Field{.Disp, 0, 0, 0}
ADDR_1 :: Bit_Field{.DispAlwaysW, 0, 0, 1}


sim8086_table_init :: proc() -> [133]Instruction_Encoding {

	return {
		// MOV
	 	enc(.mov, B(0b100010, 6), D, W, MOD, REG, RM),
		enc(.mov, B(0b1100011, 7), W, MOD, B(0b000, 3), RM, DATA, DATA_IF_W, Imp(.D, 0)),
		enc(.mov, B(0b1011, 4), W, REG, DATA, DATA_IF_W, Imp(.D, 1)),
		enc(
			.mov,
			B(0b1010000, 7),
			W,
			ADDR_0,
			ADDR_1,
			Imp(.REG, 0),
			Imp(.MOD, 0),
			Imp(.RM, 0b110),
			Imp(.D, 1),
		),
		enc(
			.mov,
			B(0b1010001, 7),
			W,
			ADDR_0,
			ADDR_1,
			Imp(.REG, 0),
			Imp(.MOD, 0),
			Imp(.RM, 0b110),
			Imp(.D, 0),
		),
		enc(.mov, B(0b100011, 6), D, B(0b0, 1), MOD, B(0b0, 1), SR, RM, Imp(.W, 1)),

		// PUSH
		enc(.push, B(0b11111111, 8), MOD, B(0b110, 3), RM, Imp(.W, 1), Imp(.D, 1)),
		enc(.push, B(0b01010, 5), REG, Imp(.W, 1), Imp(.D, 1)),
		enc(.push, B(0b000, 3), SR, B(0b110, 3), Imp(.W, 1), Imp(.D, 1)),

		// POP
		enc(.pop, B(0b10001111, 8), MOD, B(0b000, 3), RM, Imp(.W, 1), Imp(.D, 1)),
		enc(.pop, B(0b01011, 5), REG, Imp(.W, 1), Imp(.D, 1)),
		enc(.pop, B(0b000, 3), SR, B(0b111, 3), Imp(.W, 1), Imp(.D, 1)),

		// XCHG
		enc(.xchg, B(0b1000011, 7), W, MOD, REG, RM, Imp(.D, 1)),
		enc(.xchg, B(0b10010, 5), REG, Imp(.MOD, 0b11), Imp(.W, 1), Imp(.RM, 0)),

		// IN / OUT
		enc(.in_, B(0b1110010, 7), W, DATA, Imp(.REG, 0), Imp(.D, 1)),
		enc(
			.in_,
			B(0b1110110, 7),
			W,
			Imp(.REG, 0),
			Imp(.D, 1),
			Imp(.MOD, 0b11),
			Imp(.RM, 2),
			Bit_Field{.RMRegAlwaysW, 0, 0, 1},
		),
		enc(.out_, B(0b1110011, 7), W, DATA, Imp(.REG, 0), Imp(.D, 0)),
		enc(
			.out_,
			B(0b1110111, 7),
			W,
			Imp(.REG, 0),
			Imp(.D, 0),
			Imp(.MOD, 0b11),
			Imp(.RM, 2),
			Bit_Field{.RMRegAlwaysW, 0, 0, 1},
		),
		enc(.xlat, B(0b11010111, 8)),
		enc(.lea, B(0b10001101, 8), MOD, REG, RM, Imp(.D, 1), Imp(.W, 1)),
		enc(.lds, B(0b11000101, 8), MOD, REG, RM, Imp(.D, 1), Imp(.W, 1)),
		enc(.les, B(0b11000100, 8), MOD, REG, RM, Imp(.D, 1), Imp(.W, 1)),
		enc(.lahf, B(0b10011111, 8)),
		enc(.sahf, B(0b10011110, 8)),
		enc(.pushf, B(0b10011100, 8)),
		enc(.popf, B(0b10011101, 8)),

		// ADD
		enc(.add, B(0b000000, 6), D, W, MOD, REG, RM),
		enc(.add, B(0b100000, 6), S, W, MOD, B(0b000, 3), RM, DATA, DATA_IF_W),
		enc(.add, B(0b0000010, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),

		// ADC
		enc(.adc, B(0b000100, 6), D, W, MOD, REG, RM),
		enc(.adc, B(0b100000, 6), S, W, MOD, B(0b010, 3), RM, DATA, DATA_IF_W),
		enc(.adc, B(0b0001010, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),

		// INC
		enc(.inc, B(0b1111111, 7), W, MOD, B(0b000, 3), RM, Imp(.D, 1)),
		enc(.inc, B(0b01000, 5), REG, Imp(.W, 1), Imp(.D, 1)),
		enc(.aaa, B(0b00110111, 8)),
		enc(.daa, B(0b00100111, 8)),

		// SUB
		enc(.sub, B(0b001010, 6), D, W, MOD, REG, RM),
		enc(.sub, B(0b100000, 6), S, W, MOD, B(0b101, 3), RM, DATA, DATA_IF_W),
		enc(.sub, B(0b0010110, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),

		// SBB
		enc(.sbb, B(0b000110, 6), D, W, MOD, REG, RM),
		enc(.sbb, B(0b100000, 6), S, W, MOD, B(0b011, 3), RM, DATA, DATA_IF_W),
		enc(.sbb, B(0b0001110, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),

		// DEC
		enc(.dec, B(0b1111111, 7), W, MOD, B(0b001, 3), RM, Imp(.D, 1)),
		enc(.dec, B(0b01001, 5), REG, Imp(.W, 1), Imp(.D, 1)),
		enc(.neg, B(0b1111011, 7), W, MOD, B(0b011, 3), RM),

		// CMP
		enc(.cmp, B(0b001110, 6), D, W, MOD, REG, RM),
		enc(.cmp, B(0b100000, 6), S, W, MOD, B(0b111, 3), RM, DATA, DATA_IF_W),
		enc(.cmp, B(0b0011110, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),
		enc(.aas, B(0b00111111, 8)),
		enc(.das, B(0b00101111, 8)),
		enc(.mul, B(0b1111011, 7), W, MOD, B(0b100, 3), RM, Imp(.S, 0)),
		enc(.imul, B(0b1111011, 7), W, MOD, B(0b101, 3), RM, Imp(.S, 1)),
		enc(.aam, B(0b11010100, 8), B(0b00001010, 8)),
		enc(.div, B(0b1111011, 7), W, MOD, B(0b110, 3), RM, Imp(.S, 0)),
		enc(.idiv, B(0b1111011, 7), W, MOD, B(0b111, 3), RM, Imp(.S, 1)),
		enc(.aad, B(0b11010101, 8), B(0b00001010, 8)),
		enc(.cbw, B(0b10011000, 8)),
		enc(.cwd, B(0b10011001, 8)),
		enc(.not_, B(0b1111011, 7), W, MOD, B(0b010, 3), RM),
		enc(.shl, B(0b110100, 6), V, W, MOD, B(0b100, 3), RM),
		enc(.shr, B(0b110100, 6), V, W, MOD, B(0b101, 3), RM),
		enc(.sar, B(0b110100, 6), V, W, MOD, B(0b111, 3), RM),
		enc(.rol, B(0b110100, 6), V, W, MOD, B(0b000, 3), RM),
		enc(.ror, B(0b110100, 6), V, W, MOD, B(0b001, 3), RM),
		enc(.rcl, B(0b110100, 6), V, W, MOD, B(0b010, 3), RM),
		enc(.rcr, B(0b110100, 6), V, W, MOD, B(0b011, 3), RM),

		// AND
		enc(.and_, B(0b001000, 6), D, W, MOD, REG, RM),
		enc(.and_, B(0b1000000, 7), W, MOD, B(0b100, 3), RM, DATA, DATA_IF_W),
		enc(.and_, B(0b0010010, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),

		// TEST
		enc(.test, B(0b1000010, 7), W, MOD, REG, RM),
		enc(.test, B(0b1111011, 7), W, MOD, B(0b000, 3), RM, DATA, DATA_IF_W),
		enc(.test, B(0b1010100, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),

		// OR
		enc(.or_, B(0b000010, 6), D, W, MOD, REG, RM),
		enc(.or_, B(0b1000000, 7), W, MOD, B(0b001, 3), RM, DATA, DATA_IF_W),
		enc(.or_, B(0b0000110, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),

		// XOR
		enc(.xor_, B(0b001100, 6), D, W, MOD, REG, RM),
		enc(.xor_, B(0b1000000, 7), W, MOD, B(0b110, 3), RM, DATA, DATA_IF_W),
		enc(.xor_, B(0b0011010, 7), W, DATA, DATA_IF_W, Imp(.REG, 0), Imp(.D, 1)),
		enc(.rep, B(0b1111001, 7), Z),
		enc(.movs, B(0b1010010, 7), W),
		enc(.cmps, B(0b1010011, 7), W),
		enc(.scas, B(0b1010111, 7), W),
		enc(.lods, B(0b1010110, 7), W),
		enc(.stos, B(0b1010101, 7), W),

		// CALL
		enc(.call, B(0b11101000, 8), ADDR_0, ADDR_1, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.call, B(0b11111111, 8), MOD, B(0b010, 3), RM, Imp(.W, 1)),
		enc(
			.call,
			B(0b10011010, 8),
			ADDR_0,
			ADDR_1,
			DATA,
			DATA_IF_W,
			Imp(.W, 1),
			Bit_Field{.Far, 0, 0, 1},
		),
		enc(.call, B(0b11111111, 8), MOD, B(0b011, 3), RM, Imp(.W, 1), Bit_Field{.Far, 0, 0, 1}),

		// JMP
		enc(.jmp, B(0b11101001, 8), ADDR_0, ADDR_1, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jmp, B(0b11101011, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jmp, B(0b11111111, 8), MOD, B(0b100, 3), RM, Imp(.W, 1)),
		enc(
			.jmp,
			B(0b11101010, 8),
			ADDR_0,
			ADDR_1,
			DATA,
			DATA_IF_W,
			Imp(.W, 1),
			Bit_Field{.Far, 0, 0, 1},
		),
		enc(.jmp, B(0b11111111, 8), MOD, B(0b101, 3), RM, Imp(.W, 1), Bit_Field{.Far, 0, 0, 1}),
		enc(.ret, B(0b11000011, 8)),
		enc(.ret, B(0b11000010, 8), DATA, DATA_IF_W, Imp(.W, 1)),
		enc(.retf, B(0b11001011, 8), Bit_Field{.Far, 0, 0, 1}),
		enc(.retf, B(0b11001010, 8), DATA, DATA_IF_W, Imp(.W, 1), Bit_Field{.Far, 0, 0, 1}),
		enc(.je, B(0b01110100, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jl, B(0b01111100, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jle, B(0b01111110, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jb, B(0b01110010, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jbe, B(0b01110110, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jp, B(0b01111010, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jo, B(0b01110000, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.js, B(0b01111000, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jne, B(0b01110101, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jnl, B(0b01111101, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jg, B(0b01111111, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jnb, B(0b01110011, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.ja, B(0b01110111, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jnp, B(0b01111011, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jno, B(0b01110001, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jns, B(0b01111001, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.loop, B(0b11100010, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.loopz, B(0b11100001, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.loopnz, B(0b11100000, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.jcxz, B(0b11100011, 8), DISP, Bit_Field{.RelJMPDisp, 0, 0, 1}),
		enc(.int_, B(0b11001101, 8), DATA),
		enc(.int3, B(0b11001100, 8)),
		enc(.into, B(0b11001110, 8)),
		enc(.iret, B(0b11001111, 8)),
		enc(.clc, B(0b11111000, 8)),
		enc(.cmc, B(0b11110101, 8)),
		enc(.stc, B(0b11111001, 8)),
		enc(.cld, B(0b11111100, 8)),
		enc(.std, B(0b11111101, 8)),
		enc(.cli, B(0b11111010, 8)),
		enc(.sti, B(0b11111011, 8)),
		enc(.hlt, B(0b11110100, 8)),
		enc(.wait_, B(0b10011011, 8)),
		enc(.esc, B(0b11011, 5), XXX, MOD, YYY, RM),
		enc(.lock, B(0b11110000, 8)),
		enc(.segment, B(0b001, 3), SR, B(0b110, 3)),
	}

}
