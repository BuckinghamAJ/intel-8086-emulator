package decoder

import "core:fmt"
import "core:strings"

general_op_code_checks :: proc(s1: string, dtc: ^Transfer_Code) {
	if ok := strings.has_prefix(s1, "000000"); ok {dtc^ = .ADD}
	if ok := strings.has_prefix(s1, "0000010"); ok {dtc^ = .ADD}
	if ok := strings.has_prefix(s1, "001010"); ok {dtc^ = .SUB}
	if ok := strings.has_prefix(s1, "0010110"); ok {dtc^ = .SUB}
	if ok := strings.has_prefix(s1, "001110"); ok {dtc^ = .CMP}
	if ok := strings.has_prefix(s1, "0011110"); ok {dtc^ = .CMP}
}

_general_bit_string_to_opt :: proc(s: string) -> Opcode_Variant {
	switch {
	case strings.has_prefix(s, "0000010"), strings.has_prefix(s, "0010110"), strings.has_prefix(s, "0011110"):
		return .IMMEDIATE_TO_ACCUMULATOR
	case strings.has_prefix(s, "100000"):
		return .IMMEDIATE_TO_REGMEM
	case strings.has_prefix(s, "000000"), strings.has_prefix(s, "001010"), strings.has_prefix(s, "001110"):
		return .REGMEM_WITH_REG
	}

	return .UNDEFINED
}

/*
Decoding add opcode type in bits.

Parameters
-  s1 - Bytes in string format to match on
-  data - data block of bytes to continue reading
- i - index into that current block
- instructions - Address to the ByteInstructions we are creating

Returning:
- incr => The amount to increment the index pointer.
*/
decode_instructions :: proc(
	s1: string,
	data: []byte,
	i: int,
	code: Transfer_Code,
	instructions: ^[dynamic]ByteInstructions,
) -> (
	incr: int,
) {

	switch _general_bit_string_to_opt(s1) {
	case .REGMEM_WITH_REG:
		incr += decode_regmem_with_reg(s1, data, i, code, instructions)
	case .IMMEDIATE_TO_ACCUMULATOR:
		switch s1[7] {
		case '0':
			b2 := data[i + 1]
			incr += 1
			append(instructions, make_accumulator_immediate(s1, code, data = u8(b2)))
		case '1':
			b2 := data[i + 1]
			b3 := data[i + 2]
			incr += 2

			append(
				instructions,
				make_accumulator_immediate(s1, code, data = (u16(b3) << 8) | u16(b2)),
			)
		}
	case .IMMEDIATE_TO_REGMEM:
		s2 := fmt.tprintf("%08b", data[i + 1])
		incr += 1

		switch bit_string_to_mod_field_code(string(s2[0:2])) {
		case .REG_MODE:
			switch s1[6:8] {
			case "11":
				b3 := data[i + 2]
				incr += 1
				append(instructions, make_immediate_with_mod(s1, s2, code, data = u8(b3)))
			case "01":
				b3 := data[i + 2]
				b4 := data[i + 3]
				incr += 2
				append(
					instructions,
					make_immediate_with_mod(s1, s2, code, data = le_bytes_to_u16(b3, b4)),
				)

			}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			if string(s2[5:8]) == "110" {

				switch s1[6:8] {
				case "00", "11":
					append(
						instructions,
						make_immediate_with_mod(
							s1,
							s2,
							code,
							displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
							data = u8(data[i + 4]),
						),
					)
					incr += 3
				case "01":
					append(
						instructions,
						make_immediate_with_mod(
							s1,
							s2,
							code,
							displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
							data = le_bytes_to_u16(data[i + 4], data[i + 5]),
						),
					)
					incr += 4
				}
			} else {
				switch s1[6:8] {
				case "00", "11":
					append(
						instructions,
						make_immediate_with_mod(s1, s2, code, data = u8(data[i + 2])),
					)
					incr += 1
				case "01":
					append(
						instructions,
						make_immediate_with_mod(
							s1,
							s2,
							code,
							data = le_bytes_to_u16(data[i + 2], data[i + 3]),
						),
					)
					incr += 2
				}
			}
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			switch s1[6:8] {
			case "00", "11":
				append(
					instructions,
					make_immediate_with_mod(
						s1,
						s2,
						code,
						displacement = u8(data[i + 2]),
						data = u8(data[i + 3]),
					),
				)
				incr += 2
			case "01":
				append(
					instructions,
					make_immediate_with_mod(
						s1,
						s2,
						code,
						displacement = u8(data[i + 2]),
						data = le_bytes_to_u16(data[i + 3], data[i + 4]),
					),
				)
				incr += 3

			}
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			switch s1[6:8] {
			case "11":
				append(
					instructions,
					make_immediate_with_mod(
						s1,
						s2,
						code,
						displacement = le_bytes_to_u16(data[i + 2], data[i + 3]),
						data = u8(data[i + 4]),
					),
				)
				incr += 3
			case "01":
				append(
					instructions,
					make_immediate_with_mod(
						s1,
						s2,
						code,
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
	case .UNDEFINED:
		msg := fmt.tprint("Undefined opcode for byte: ", s1)
		panic(msg)
	case .IMMEDIATE_TO_REG_NO_MOD, .ACCUMULATOR_MEMORY:
		msg := fmt.tprint("Unexpected opcode variant in ADD/SUB/CMP decode for byte: ", s1)
		panic(msg)
	}

	return incr
}
