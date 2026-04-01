package decoder

import "core:strings"
import "core:fmt"
Mod_Field_Code :: enum {
	UNDEFINED,
	MEMORY_MODE_NO_DISPLACEMENT,
	MEMORY_MODE_8_BIT_DISPLACEMENT,
	MEMORY_MODE_16_BIT_DISPLACEMENT,
	REG_MODE,
}

Mov_Opcode :: enum {
	UNDEFINED,
	REGISTER_TO_REGISTER,
	IMMEDIATE_TO_REG_NO_DISP,
	IMMEDIATE_TO_REG_DISP
}

le_bytes_to_u16 :: proc(low: u8, high: u8) -> u16 {
	return (u16(high) << 8) | u16(low)
}

bit_string_to_opt :: proc(s: string) -> Mov_Opcode {
	if strings.has_prefix(s, "1011") {
		return .IMMEDIATE_TO_REG_NO_DISP
	} else if strings.has_prefix(s, "1100011") {
		return .IMMEDIATE_TO_REG_DISP
	} else if strings.has_prefix(s, "100010") {
		return .REGISTER_TO_REGISTER
	}

	return .UNDEFINED
}

bit_string_to_mod_field_code :: proc(s: string) -> Mod_Field_Code {

	switch s {
	case "00": return .MEMORY_MODE_NO_DISPLACEMENT
	case "01": return .MEMORY_MODE_8_BIT_DISPLACEMENT
	case "10": return .MEMORY_MODE_16_BIT_DISPLACEMENT
	case "11": return .REG_MODE
	}
	return .UNDEFINED
}



mov_register_mode_no_data :: proc(s1: string, s2: string) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:6]),
			direction = rune(s1[6]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			reg = string(s2[2:5]),
			rm = string(s2[5:8]),
		},
		method_name = "mov_register_mode_no_data",
	}
}

mov_register_mode_u8data :: proc(s1: string, s2: string, data: u8) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			direction = '0',
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		data = data,
		method_name = "mov_register_mode_u8data",
	}
}

mov_register_mode_u16data :: proc(s1: string, s2: string, data: u16) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			direction = '0',
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		data = data,
		method_name = "mov_register_mode_u16data",
	}
}

mov_register_mode :: proc{
	mov_register_mode_no_data,
	mov_register_mode_u8data,
	mov_register_mode_u16data
}

mov_memory_mode_no_disp_not_110 :: proc(s1: string, s2: string) -> ByteInstructions {
	rm := string(s2[5:8])

	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:6]),
			direction = rune(s1[6]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			reg = string(s2[2:5]),
			rm = string(s2[5:8]),
		},
		method_name = "mov_memory_mode_no_disp_not_110",
	}
}

mov_memory_mode_no_disp_110 :: proc(s1: string, s2: string, displacement: u16) -> ByteInstructions {

	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:6]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			reg = string(s2[2:5]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		method_name = "mov_memory_mode_no_disp_110",
	}
}

mov_memory_no_disp_110_with_u8data :: proc(s1: string, s2: string, displacement: u16, data: u8) -> ByteInstructions {

	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_no_disp_110_with_u8data",
	}
}

mov_memory_no_disp_110_with_u16data :: proc(s1: string, s2: string, displacement: u16, data: u16) -> ByteInstructions {

	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_no_disp_110_with_u16data",
	}
}

mov_memory_no_disp_with_u8data :: proc(s1: string, s2: string, displacement: u16, data: u8) -> ByteInstructions {

	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_no_disp_with_u8data",
	}
}

mov_memory_no_disp_with_data :: proc(s1: string, s2: string, data: union {u8, u16}) -> ByteInstructions {

	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		data = data,
		method_name = "mov_memory_no_disp_with_data",
	}
}

mov_memory_no_displacement :: proc{
	mov_memory_mode_no_disp_110,
	mov_memory_mode_no_disp_not_110,
	mov_memory_no_disp_110_with_u8data,
	mov_memory_no_disp_110_with_u16data,
}


mov_memory_mode_8bit_displacement  :: proc(s1: string, s2: string, displacement: u8) ->  ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:6]),
			direction = rune(s1[6]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			reg = string(s2[2:5]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		method_name = "mov_memory_mode_8bit_displacement",
	}
}

mov_memory_mode_16bit_displacement :: proc(s1: string, s2: string, displacement: u16) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:6]),
			direction = rune(s1[6]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			reg = string(s2[2:5]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		method_name = "mov_memory_mode_16bit_displacement",
	}
}

mov_memory_mode_8bit_displacement_data :: proc(s1: string, s2: string, displacement: u8, data: u8) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_mode_8bit_displacement_data",
	}
}

mov_memory_mode_16bit_displacement_data :: proc(s1: string, s2: string, displacement: u16, data: u16) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_mode_16bit_displacement_data",
	}
}

mov_memory_mode_u16displacement_u8data :: proc(s1: string, s2: string, displacement: u16, data: u8) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_mode_u16displacement_u8data",
	}
}

mov_memory_u16displacement_u8data :: proc(s1: string, s2: string, displacement: u16, data: u8) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_u16displacement_u8data",
	}
}

mov_memory_mode_u8displacement_u16data :: proc(s1: string, s2: string, displacement: u8, data: u16) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		byte1 = Byte1{
			opcode = string(s1[0:7]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{
			mod = string(s2[0:2]),
			rm = string(s2[5:8]),
		},
		displacement = displacement,
		data = data,
		method_name = "mov_memory_mode_u8displacement_u16data",
	}
}


mov_memory_mode_displacement :: proc{
	mov_memory_mode_8bit_displacement,
	mov_memory_mode_16bit_displacement,
	mov_memory_mode_8bit_displacement_data,
	mov_memory_mode_16bit_displacement_data,
	mov_memory_mode_u16displacement_u8data,
	mov_memory_mode_u8displacement_u16data
}

mov_immediate_to_register_u8 :: proc(s1: string, data: u8) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		opcode = string(s1[0:4]),
		word_op = rune(s1[4]),
		reg = string(s1[5:8]),
		data = data
	}
}

mov_immediate_to_register_u16 :: proc(s1: string, data: u16) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		opcode = string(s1[0:4]),
		word_op = rune(s1[4]),
		reg = string(s1[5:8]),
		data = data
	}
}

mov_immediate_to_register_disp_u8 :: proc(s1: string, s2: string, data: u8, displacement: u8) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		opcode = string(s1[0:7]),
		word_op = rune(s1[7]),
		mod = string(s2[0:2]),
		rm = string(s2[5:8]),
		data = data,
		displacement = displacement,
	}
}

mov_immediate_to_register_disp_u16 :: proc(s1: string, s2: string, data: u16, displacement: u16) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		opcode = string(s1[0:7]),
		word_op = rune(s1[7]),
		mod = string(s2[0:2]),
		rm = string(s2[5:8]),
		data = data,
		displacement = displacement,
	}
}

mov_imediate_to_register_u16disp_u8 :: proc(s1: string, s2: string, data: u8, displacement: u16) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		opcode = string(s1[0:7]),
		word_op = rune(s1[7]),
		mod = string(s2[0:2]),
		rm = string(s2[5:8]),
		data = data,
		displacement = displacement,
	}
}

mov_imediate_to_register_u8disp_u16 :: proc(s1: string, s2: string, data: u16, displacement: u8) -> ByteInstructions {
	return ByteInstructions{
		code = .MOV,
		opcode = string(s1[0:7]),
		word_op = rune(s1[7]),
		mod = string(s2[0:2]),
		rm = string(s2[5:8]),
		data = data,
		displacement = displacement,
	}
}

mov_immediate_to_register :: proc{
	mov_immediate_to_register_u8,
	mov_immediate_to_register_u16,
	mov_immediate_to_register_disp_u8,
	mov_immediate_to_register_disp_u16,
	mov_imediate_to_register_u16disp_u8,
	mov_imediate_to_register_u8disp_u16,
}

reg_assembly_data :: proc(data : union{u8, u16}) -> string {
	return fmt.tprintf("%d", data)
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

reg_assembly :: proc{
	reg_assembly_table,
	reg_assembly_data
}

rm_assembly :: proc(bi: ByteInstructions, mod: Mod_Field_Code) -> (s: string, err: Error) {
	word_op := bi.word_op
	rm := bi.rm

	assert(word_op == '0' || word_op == '1', "Invalid word_op value. Expected '0' or '1'.")

	switch rm {
	case "000":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "AL", .None} else {return "AX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BX + SI]" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + SI + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + SI + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "001":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "CL", .None} else {return "CX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BX + DI]" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + DI + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + DI + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "010":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "DL", .None} else {return "DX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BP + SI]" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + SI + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + SI + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "011":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "BL", .None} else {return "BX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BP + DI]" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + DI + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BP + DI + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "100":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "AH", .None} else {return "SP", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[SI]" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[SI + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[SI + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "101":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "CH", .None} else {return "BP", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[DI]" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[DI + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[DI + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "110":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "DH", .None} else {return "SI", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return fmt.tprintf("[%d]", bi.data) , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			if bi.displacement == u8(0) {
				return "[BP]", .None
			}
			return fmt.tprintf("[BP + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			if bi.displacement == u16(0) {
				return "[BP]", .None
			}
			return fmt.tprintf("[BP + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "111":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "BH", .None} else {return "DI", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "[BX]" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + %d]", bi.displacement), .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return fmt.tprintf("[BX + %d]", bi.displacement), .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	}


	return "UNKNOWN", .Error_Rm_Assembly
}


mov_create_assembly_instructions_from :: proc(byte_instruction: ByteInstructions) -> (ai: AssemblyInstructions, err: Error) {
	assembly_instruction := AssemblyInstructions{
		code = byte_instruction.code,
		mod_field = bit_string_to_mod_field_code(byte_instruction.byte2.mod),
	}

	direction, ok := byte_instruction.direction.?
	if ok {
		switch direction {
		case '0' :
			assembly_instruction.source = reg_assembly(byte_instruction.reg, byte_instruction.word_op)
			assembly_instruction.destination = rm_assembly(byte_instruction, assembly_instruction.mod_field) or_return
		case '1' :
			assembly_instruction.source = rm_assembly(byte_instruction, assembly_instruction.mod_field) or_return
			assembly_instruction.destination = reg_assembly(byte_instruction.reg, byte_instruction.word_op)
		}

	} else {

		if byte_instruction.rm != "" {
			assembly_instruction.source = reg_assembly(byte_instruction.data)
			assembly_instruction.destination = rm_assembly(byte_instruction, assembly_instruction.mod_field) or_return
		} else {

			assembly_instruction.destination = reg_assembly(byte_instruction.reg, byte_instruction.word_op)
			assembly_instruction.source = fmt.tprintf("%d", byte_instruction.data)
		}



	}

	return assembly_instruction, .None

}

decode_mov :: proc(s1: string, data: []byte, i: int, instructions: ^[dynamic]ByteInstructions) -> (incr: int) {
	incr = 0

	switch bit_string_to_opt(s1) {
	case .REGISTER_TO_REGISTER:
		s2 := fmt.tprintf("%08b", data[i + 1])
		incr += 1

		switch bit_string_to_mod_field_code(string(s2[0:2])) {
		case .REG_MODE:
			append(instructions, mov_register_mode(s1, s2))
		case .MEMORY_MODE_NO_DISPLACEMENT:
			if string(s2[5:8]) == "110" {
				append(
					instructions,
					mov_memory_no_displacement(
						s1,
						s2,
						le_bytes_to_u16(data[i + 2], data[i + 3]),
					),
				)
				incr += 2
			} else {
				append(instructions, mov_memory_no_displacement(s1, s2))
			}
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			append(instructions, mov_memory_mode_displacement(s1, s2, u8(data[i + 2])))
			incr += 1
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(
				instructions,
				mov_memory_mode_displacement(
					s1,
					s2,
					le_bytes_to_u16(data[i + 2], data[i + 3]),
				),
			)
			incr += 2
		case .UNDEFINED:
			msg := fmt.tprint(
				"Undefined Mod_Field_Code for instruction with bytes: ",
				s1,
				s2,
			)
			panic(msg)
		}
	case .IMMEDIATE_TO_REG_NO_DISP:
		switch s1[4] {
		case '0':
			b2 := data[i + 1]
			incr += 1
			append(instructions, mov_immediate_to_register(s1, u8(b2)))
		case '1':
			b2 := data[i + 1]
			b3 := data[i + 2]
			incr += 2

			append(instructions, mov_immediate_to_register(s1, (u16(b3) << 8) | u16(b2)))
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
				append(instructions, mov_register_mode(s1, s2, u8(b3)))
			case '1':
				b3 := data[i + 2]
				b4 := data[i + 3]
				incr += 2
				append(instructions, mov_register_mode(s1, s2, (u16(b4) << 8) | u16(b3)))

			}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			if string(s2[5:8]) == "110" {

				switch s1[7] {
				case '0':
					append(
						instructions,
						mov_memory_no_displacement(
							s1,
							s2,
							le_bytes_to_u16(data[i + 2], data[i + 3]),
							u8(data[i + 4]),
						),
					)
					incr += 3
				case '1':
					append(
						instructions,
						mov_memory_no_displacement(
							s1,
							s2,
							le_bytes_to_u16(data[i + 2], data[i + 3]),
							le_bytes_to_u16(data[i + 4], data[i + 5]),
						),
					)
					incr += 4
				}
			} else {
				switch s1[7] {
				case '0':
					append(
						instructions,
						mov_memory_no_disp_with_data(s1, s2, u8(data[i + 2])),
					)
					incr += 1
				case '1':
					append(
						instructions,
						mov_memory_no_disp_with_data(
							s1,
							s2,
							le_bytes_to_u16(data[i + 2], data[i + 3]),
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
					mov_memory_mode_displacement(s1, s2, u8(data[i + 2]), u8(data[i + 3])),
				)
				incr += 2
			case '1':
				append(
					instructions,
					mov_memory_mode_displacement(
						s1,
						s2,
						u8(data[i + 2]),
						le_bytes_to_u16(data[i + 3], data[i + 4]),
					),
				)
				incr += 3

			}
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			switch s1[7] {
			case '0':
				append(
					instructions,
					mov_memory_mode_displacement(
						s1,
						s2,
						le_bytes_to_u16(data[i + 2], data[i + 3]),
						u8(data[i + 4]),
					),
				)
				incr += 3
			case '1':
				append(
					instructions,
					mov_memory_mode_displacement(
						s1,
						s2,
						le_bytes_to_u16(data[i + 2], data[i + 3]),
						le_bytes_to_u16(data[i + 4], data[i + 5]),
					),
				)
				incr += 4
			}
		case .UNDEFINED:
			msg := fmt.tprint(
				"Undefined Mod_Field_Code for instruction with bytes: ",
				s1,
				s2,
			)
			panic(msg)
		}
	case .UNDEFINED:
		msg := fmt.tprint("Undefined opcode for byte: ", s1)
		panic(msg)
	}

	return incr
}
