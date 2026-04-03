package decoder

import "core:fmt"
import "core:strings"
Mod_Field_Code :: enum {
	UNDEFINED,
	MEMORY_MODE_NO_DISPLACEMENT,
	MEMORY_MODE_8_BIT_DISPLACEMENT,
	MEMORY_MODE_16_BIT_DISPLACEMENT,
	REG_MODE,
}

Mov_Errors :: enum {
	Invalid_Mod_Field_Code,
	Undefined_Memory_Mode,
	Error_Rm_Assembly,

}

Mov_Opcode :: enum {
	UNDEFINED,
	REGISTER_TO_REGISTER,
	IMMEDIATE_TO_REG_NO_DISP,
	IMMEDIATE_TO_REG_DISP,
	MEMORY_TO_ACCUMULATOR,
	ACCUMULATOR_TO_MEMORY,
}

le_bytes_to_u16 :: proc(low: u8, high: u8) -> u16 {
	return (u16(high) << 8) | u16(low)
}

bit_string_to_opt :: proc(s: string) -> Mov_Opcode {

	switch {
	case strings.has_prefix(s, "1011"):
		return .IMMEDIATE_TO_REG_NO_DISP
	case strings.has_prefix(s, "1100011"):
		return .IMMEDIATE_TO_REG_DISP
	case strings.has_prefix(s, "100010"):
		return .REGISTER_TO_REGISTER
	case strings.has_prefix(s, "1010000"):
		return .MEMORY_TO_ACCUMULATOR
	case strings.has_prefix(s, "1010001"):
		return .ACCUMULATOR_TO_MEMORY
	}

	return .UNDEFINED
}

bit_string_to_mod_field_code :: proc(s: string) -> Mod_Field_Code {

	switch s {
	case "00":
		return .MEMORY_MODE_NO_DISPLACEMENT
	case "01":
		return .MEMORY_MODE_8_BIT_DISPLACEMENT
	case "10":
		return .MEMORY_MODE_16_BIT_DISPLACEMENT
	case "11":
		return .REG_MODE
	}
	return .UNDEFINED
}


make_mov_reg_to_reg :: proc(s1: string, s2: string, displacement: union {
		u8,
		u16,
	} = nil, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = .MOV,
		byte1 = Byte1{opcode = string(s1[0:6]), direction = rune(s1[6]), word_op = rune(s1[7])},
		byte2 = Byte2{mod = string(s2[0:2]), reg = string(s2[2:5]), rm = string(s2[5:8])},
		displacement = displacement,
		data = data,
	}
}

make_mov_immediate_with_mod :: proc(s1: string, s2: string, displacement: union {
		u8,
		u16,
	} = nil, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = .MOV,
		byte1 = Byte1{opcode = string(s1[0:7]), word_op = rune(s1[7])},
		byte2 = Byte2{mod = string(s2[0:2]), rm = string(s2[5:8])},
		displacement = displacement,
		data = data,
	}
}

make_mov_immediate_to_reg :: proc(s1: string, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = .MOV,
		byte1 = Byte1{opcode = string(s1[0:4]), word_op = rune(s1[4])},
		byte2 = Byte2{reg = string(s1[5:8])},
		data = data,
	}
}

mov_memory_accumulator :: proc(s1: string, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = .MOV,
		opcode = string(s1[0:7]),
		direction = rune(s1[6]),
		word_op = rune(s1[7]),
		reg = "000",
		data = data,
	}
}

reg_assembly_data :: proc(data: union {
		u8,
		u16,
	}) -> string {
	result : string

	switch u_type in data{
	case u8:
		result = fmt.tprintf("byte %d", data)
	case u16:
		result = fmt.tprintf("word %d", data)
	}

 	return result
}


reg_assembly_table :: proc(reg: string, word_op: rune) -> string {

	assert(word_op == '0' || word_op == '1', "Invalid word_op value. Expected '0' or '1'.")

	switch reg {
	case "000":
		if word_op == '0' {return "AL"} else {return "AX"}
	case "001":
		if word_op == '0' {return "CL"} else {return "CX"}
	case "010":
		if word_op == '0' {return "DL"} else {return "DX"}
	case "011":
		if word_op == '0' {return "BL"} else {return "BX"}
	case "100":
		if word_op == '0' {return "AH"} else {return "SP"}
	case "101":
		if word_op == '0' {return "CH"} else {return "BP"}
	case "110":
		if word_op == '0' {return "DH"} else {return "SI"}
	case "111":
		if word_op == '0' {return "BH"} else {return "DI"}
	}

	return "UNKNOWN"
}

reg_assembly :: proc {
	reg_assembly_table,
	reg_assembly_data,
}

rm_assembly :: proc(bi: ByteInstructions, mod: Mod_Field_Code) -> (s: string, err: Error) {
	word_op := bi.word_op
	rm := bi.rm

	assert(word_op == '0' || word_op == '1', "Invalid word_op value. Expected '0' or '1'.")

	switch rm {
	case "000":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "AL", nil} else {return "AX", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BX + SI]", nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + SI + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + SI + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "001":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "CL", nil} else {return "CX", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BX + DI]", nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + DI + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + DI + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "010":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "DL", nil} else {return "DX", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BP + SI]", nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + SI + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + SI + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "011":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "BL", nil} else {return "BX", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BP + DI]", nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + DI + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + DI + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "100":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "AH", nil} else {return "SP", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[SI]", nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[SI + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[SI + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "101":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "CH", nil} else {return "BP", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[DI]", nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[DI + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[DI + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "110":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "DH", nil} else {return "SI", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return fmt.tprintf("[%d]", bi.data), nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			if bi.displacement == u8(0) {
				return "[BP]", nil
			}
			return fmt.tprintf("[BP + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			if bi.displacement == u16(0) {
				return "[BP]", nil
			}
			return fmt.tprintf("[BP + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "111":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "BH", nil} else {return "DI", nil}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BX]", nil
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + %d]", bi.displacement), nil
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + %d]", bi.displacement), nil
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	}


	return "UNKNOWN", .Error_Rm_Assembly
}

mov_reg_assembly_instructions :: proc(
	bi: ByteInstructions,
) -> (
	ai: AssemblyInstructions,
	err: Error,
) {
	assembly_instruction := AssemblyInstructions {
		code      = bi.code,
		mod_field = bit_string_to_mod_field_code(bi.mod),
	}

	direction, ok := bi.direction.?
	if ok {
		switch direction {
		case '0':
			assembly_instruction.source = reg_assembly(bi.reg, bi.word_op)
			assembly_instruction.destination = rm_assembly(
				bi,
				assembly_instruction.mod_field,
			) or_return
		case '1':
			assembly_instruction.source = rm_assembly(bi, assembly_instruction.mod_field) or_return
			assembly_instruction.destination = reg_assembly(bi.reg, bi.word_op)
		}

	} else {

		if bi.rm != "" {
			assembly_instruction.source = reg_assembly(bi.data)
			assembly_instruction.destination = rm_assembly(
				bi,
				assembly_instruction.mod_field,
			) or_return
		} else {

			assembly_instruction.destination = reg_assembly(bi.reg, bi.word_op)
			assembly_instruction.source = fmt.tprintf("%d", bi.data)
		}
	}

	return assembly_instruction, nil
}

mov_mem_accumulator_instructions :: proc(
	bi: ByteInstructions,
	opt: Mov_Opcode
) -> (
	ai: AssemblyInstructions,
	err: Error,
) {
	ai = AssemblyInstructions {
		code      = bi.code,
	}

	assert(opt == .MEMORY_TO_ACCUMULATOR || opt == .ACCUMULATOR_TO_MEMORY)

	#partial switch opt {
	case .MEMORY_TO_ACCUMULATOR:
		switch bi.word_op {
			// mov ax, [2555]
			// MOV destination, source
			case '0':
				ai.destination = "AL"
			case '1':
				ai.destination = "AX"
		}
		ai.source = fmt.tprintf("[%d]", bi.data)
	case .ACCUMULATOR_TO_MEMORY:
		switch bi.word_op {
			// mov [2555], ax
			// MOV destination, source
			case '0':
				ai.source = "AL"
			case '1':
				ai.source = "AX"
		}
		ai.destination = fmt.tprintf("[%d]", bi.data)
	}

	return ai, nil

}

mov_create_assembly_instructions_from :: proc(
	byte_instruction: ByteInstructions,
) -> (
	ai: AssemblyInstructions,
	err: Error,
) {

	switch op := bit_string_to_opt(byte_instruction.opcode); op {
	case .REGISTER_TO_REGISTER, .IMMEDIATE_TO_REG_NO_DISP, .IMMEDIATE_TO_REG_DISP:
		return mov_reg_assembly_instructions(byte_instruction)
	case .MEMORY_TO_ACCUMULATOR, .ACCUMULATOR_TO_MEMORY:
		return mov_mem_accumulator_instructions(byte_instruction, op)
	case .UNDEFINED:
		return {}, .Invalid_Opcode
	}

	return ai, nil

}

decode_mov :: proc(
	s1: string,
	data: []byte,
	i: int,
	instructions: ^[dynamic]ByteInstructions,
) -> (
	incr: int,
) {
	incr = 0

	switch bit_string_to_opt(s1) {
	case .REGISTER_TO_REGISTER:
		s2 := fmt.tprintf("%08b", data[i + 1])
		incr += 1

		switch bit_string_to_mod_field_code(string(s2[0:2])) {
		case .REG_MODE:
			append(instructions, make_mov_reg_to_reg(s1, s2))
		case .MEMORY_MODE_NO_DISPLACEMENT:
			if string(s2[5:8]) == "110" {
				append(
					instructions,
					make_mov_reg_to_reg(
						s1,
						s2,
						data = le_bytes_to_u16(data[i + 2], data[i + 3]),
					),
				)
				incr += 2
			} else {
				append(instructions, make_mov_reg_to_reg(s1, s2))
			}
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			append(instructions, make_mov_reg_to_reg(s1, s2, displacement = u8(data[i + 2])))
			incr += 1
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(
				instructions,
				make_mov_reg_to_reg(
					s1,
					s2,
					displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
				),
			)
			incr += 2
		case .UNDEFINED:
			msg := fmt.tprint("Undefined Mod_Field_Code for instruction with bytes: ", s1, s2)
			panic(msg)
		}
	case .IMMEDIATE_TO_REG_NO_DISP:
		switch s1[4] {
		case '0':
			b2 := data[i + 1]
			incr += 1
			append(instructions, make_mov_immediate_to_reg(s1, data = u8(b2)))
		case '1':
			b2 := data[i + 1]
			b3 := data[i + 2]
			incr += 2

			append(instructions, make_mov_immediate_to_reg(s1, data = (u16(b3) << 8) | u16(b2)))
		}
	case .IMMEDIATE_TO_REG_DISP:
		s2 := fmt.tprintf("%08b", data[i + 1])
		incr += 1

		switch bit_string_to_mod_field_code(string(s2[0:2])) {
		case .REG_MODE:
			switch s1[7] {
			case '0':
				b3 := data[i + 2]
				incr += 1
				append(instructions, make_mov_immediate_with_mod(s1, s2, data = u8(b3)))
			case '1':
				b3 := data[i + 2]
				b4 := data[i + 3]
				incr += 2
				append(
					instructions,
					make_mov_immediate_with_mod(s1, s2, data = le_bytes_to_u16(b3, b4)),
				)

			}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			if string(s2[5:8]) == "110" {

				switch s1[7] {
				case '0':
					append(
						instructions,
						make_mov_immediate_with_mod(
							s1,
							s2,
							displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
							data = u8(data[i + 4]),
						),
					)
					incr += 3
				case '1':
					append(
						instructions,
						make_mov_immediate_with_mod(
							s1,
							s2,
							displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
							data = le_bytes_to_u16(data[i + 4], data[i + 5]),
						),
					)
					incr += 4
				}
			} else {
				switch s1[7] {
				case '0':
					append(
						instructions,
						make_mov_immediate_with_mod(s1, s2, data = u8(data[i + 2])),
					)
					incr += 1
				case '1':
					append(
						instructions,
						make_mov_immediate_with_mod(
							s1,
							s2,
							data = le_bytes_to_u16(data[i + 2], data[i + 3]),
						),
					)
					incr += 2
				}
			}
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			switch s1[7] {
			case '0':
				append(
					instructions,
					make_mov_immediate_with_mod(
						s1,
						s2,
						displacement = u8(data[i + 2]),
						data = u8(data[i + 3]),
					),
				)
				incr += 2
			case '1':
				append(
					instructions,
					make_mov_immediate_with_mod(
						s1,
						s2,
						displacement = u8(data[i + 2]),
						data = le_bytes_to_u16(data[i + 3], data[i + 4]),
					),
				)
				incr += 3

			}
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			switch s1[7] {
			case '0':
				append(
					instructions,
					make_mov_immediate_with_mod(
						s1,
						s2,
						displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
						data = u8(data[i + 4]),
					),
				)
				incr += 3
			case '1':
				append(
					instructions,
					make_mov_immediate_with_mod(
						s1,
						s2,
						displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
						data = le_bytes_to_u16(data[i + 4], data[i + 5]),
					),
				)
				incr += 4
			}
		case .UNDEFINED:
			msg := fmt.tprint("Undefined Mod_Field_Code for instruction with bytes: ", s1, s2)
			panic(msg)
		}
	case .MEMORY_TO_ACCUMULATOR, .ACCUMULATOR_TO_MEMORY:
		b2 := data[i + 1]
		incr += 1
		switch s1[7] {
		case '0':
			append(instructions, mov_memory_accumulator(s1, data = u8(b2)))
		case '1':
			b3 := data[i + 2]
			incr += 1
			append(instructions, mov_memory_accumulator(s1, data = le_bytes_to_u16(b2, b3)))
		}

	case .UNDEFINED:
		msg := fmt.tprint("Undefined opcode for byte: ", s1)
		panic(msg)
	}

	return incr
}
