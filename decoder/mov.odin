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

mov_op_code_checks :: proc(s1: string, dtc: ^Transfer_Code) {
	if ok := strings.has_prefix(s1, "110001"); ok {dtc^ = .MOV}
	if ok := strings.has_prefix(s1, "1011"); ok {dtc^ = .MOV}
	if ok := strings.has_prefix(s1, "100010"); ok {dtc^ = .MOV}
	if ok := strings.has_prefix(s1, "1010000"); ok {dtc^ = .MOV}
	if ok := strings.has_prefix(s1, "1010001"); ok {dtc^ = .MOV}
}

le_bytes_to_u16 :: proc(low: u8, high: u8) -> u16 {
	return (u16(high) << 8) | u16(low)
}

_mov_bit_string_to_opt :: proc(s: string) -> Mov_Opcode {
	switch {
	case strings.has_prefix(s, "1011"):
		return .IMMEDIATE_TO_REG_NO_DISP
	case strings.has_prefix(s, "110001"):
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

	switch op := _mov_bit_string_to_opt(byte_instruction.opcode); op {
	case .REGISTER_TO_REGISTER, .IMMEDIATE_TO_REG_NO_DISP, .IMMEDIATE_TO_REG_DISP:
		return reg_assembly_instructions(byte_instruction)
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

	switch _mov_bit_string_to_opt(s1) {
	case .REGISTER_TO_REGISTER:
		s2 := fmt.tprintf("%08b", data[i + 1])
		incr += 1

		switch bit_string_to_mod_field_code(string(s2[0:2])) {
		case .REG_MODE:
			append(instructions, make_reg_to_reg(s1, s2, code = .MOV))
		case .MEMORY_MODE_NO_DISPLACEMENT:
			if string(s2[5:8]) == "110" {
				append(
					instructions,
					make_reg_to_reg(
						s1,
						s2,
						code = .MOV,
						data = le_bytes_to_u16(data[i + 2], data[i + 3]),
					),
				)
				incr += 2
			} else {
				append(instructions, make_reg_to_reg(s1, s2, code = .MOV))
			}
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			append(instructions, make_reg_to_reg(s1, s2, code = .MOV,  displacement = u8(data[i + 2])))
			incr += 1
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(
				instructions,
				make_reg_to_reg(
					s1,
					s2,
					code = .MOV,
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
			append(instructions, make_immediate_to_reg(s1,code = .MOV, data = u8(b2)))
		case '1':
			b2 := data[i + 1]
			b3 := data[i + 2]
			incr += 2

			append(instructions, make_immediate_to_reg(s1,code = .MOV, data = (u16(b3) << 8) | u16(b2)))
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
				append(instructions, make_immediate_with_mod(s1, s2,code = .MOV, data = u8(b3)))
			case '1':
				b3 := data[i + 2]
				b4 := data[i + 3]
				incr += 2
				append(
					instructions,
					make_immediate_with_mod(s1, s2,code = .MOV, data = le_bytes_to_u16(b3, b4)),
				)

			}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			if string(s2[5:8]) == "110" {

				switch s1[7] {
				case '0':
					append(
						instructions,
						make_immediate_with_mod(
							s1,
							s2,
							code = .MOV,
							displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
							data = u8(data[i + 4]),
						),
					)
					incr += 3
				case '1':
					append(
						instructions,
						make_immediate_with_mod(
							s1,
							s2,
							code = .MOV,
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
						make_immediate_with_mod(s1, s2,code = .MOV, data = u8(data[i + 2])),
					)
					incr += 1
				case '1':
					append(
						instructions,
						make_immediate_with_mod(
							s1,
							s2,
							code = .MOV,
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
					make_immediate_with_mod(
						s1,
						s2,
						code = .MOV,
						displacement = u8(data[i + 2]),
						data = u8(data[i + 3]),
					),
				)
				incr += 2
			case '1':
				append(
					instructions,
					make_immediate_with_mod(
						s1,
						s2,
						code = .MOV,
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
					make_immediate_with_mod(
						s1,
						s2,
						code = .MOV,
						displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
						data = u8(data[i + 4]),
					),
				)
				incr += 3
			case '1':
				append(
					instructions,
					make_immediate_with_mod(
						s1,
						s2,
						code = .MOV,
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
