package decoder

import "core:fmt"
import "core:strings"

mov_op_code_checks :: #force_inline proc(b1: u8, dtc: ^Transfer_Code) {
	switch {
	case (b1 & 0b11111100) == 0b11000100: // 110001xx
		dtc^ = .MOV
	case (b1 & 0b11110000) == 0b10110000: // 1011xxxx
		dtc^ = .MOV
	case (b1 & 0b11111100) == 0b10001000: // 100010xx
		dtc^ = .MOV
	case (b1 & 0b11111110) == 0b10100000: // 1010000x
		dtc^ = .MOV
	case (b1 & 0b11111110) == 0b10100010: // 1010001x
		dtc^ = .MOV
	}
}

le_bytes_to_u16 :: proc(low: u8, high: u8) -> u16 {
	return (u16(high) << 8) | u16(low)
}

_mov_bit_string_to_opt :: proc(s: string) -> Opcode_Variant {
	switch {
	case strings.has_prefix(s, "1011"):
		return .IMMEDIATE_TO_REG_NO_MOD
	case strings.has_prefix(s, "110001"):
		return .IMMEDIATE_TO_REGMEM
	case strings.has_prefix(s, "100010"):
		return .REGMEM_WITH_REG
	case strings.has_prefix(s, "1010000"), strings.has_prefix(s, "1010001"):
		return .ACCUMULATOR_MEMORY
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
	s1: string,
) -> (
	ai: AssemblyInstructions,
	err: Error,
) {
	ai = AssemblyInstructions {
		code      = bi.code,
	}

	switch {
	case strings.has_prefix(s1, "1010000"):
		// MEMORY_TO_ACCUMULATOR
		switch bi.word_op {
			case '0':
				ai.destination = "AL"
			case '1':
				ai.destination = "AX"
		}
		ai.source = fmt.tprintf("[%d]", bi.data)
	case strings.has_prefix(s1, "1010001"):
		// ACCUMULATOR_TO_MEMORY
		switch bi.word_op {
			case '0':
				ai.source = "AL"
			case '1':
				ai.source = "AX"
		}
		ai.destination = fmt.tprintf("[%d]", bi.data)
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
	case .REGMEM_WITH_REG:
		incr += decode_regmem_with_reg(s1, data, i, .MOV, instructions)
	case .IMMEDIATE_TO_REG_NO_MOD:
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
	case .IMMEDIATE_TO_REGMEM:
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
	case .ACCUMULATOR_MEMORY:
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

	case .IMMEDIATE_TO_ACCUMULATOR:
		msg := fmt.tprint("Unexpected IMMEDIATE_TO_ACCUMULATOR variant in MOV decode for byte: ", s1)
		panic(msg)
	case .UNDEFINED:
		msg := fmt.tprint("Undefined opcode for byte: ", s1)
		panic(msg)
	}

	return incr
}
