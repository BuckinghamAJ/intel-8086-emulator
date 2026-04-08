package decoder

import "core:fmt"

check_next_byte :: proc(s2: string, dtc: ^Transfer_Code) {
	switch s2[2:5] {
	case "000":
		{dtc^ = .ADD}
	case "101":
		{dtc^ = .SUB}
	case "111":
		{dtc^ = .CMP}
	}
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

make_reg_to_reg :: proc(s1: string, s2: string, code: Transfer_Code, displacement: union {
		u8,
		u16,
	} = nil, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = code,
		byte1 = Byte1{opcode = string(s1[0:6]), direction = rune(s1[6]), word_op = rune(s1[7])},
		byte2 = Byte2{mod = string(s2[0:2]), reg = string(s2[2:5]), rm = string(s2[5:8])},
		displacement = displacement,
		data = data,
	}
}


make_immediate_with_mod :: proc(s1: string, s2: string, code: Transfer_Code, displacement: union {
		u8,
		u16,
	} = nil, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = code,
		byte1 = Byte1 {
			opcode = string(s1[0:7]),
			sign_extension = rune(s1[6]),
			word_op = rune(s1[7]),
		},
		byte2 = Byte2{mod = string(s2[0:2]), rm = string(s2[5:8])},
		displacement = displacement,
		data = data,
	}
}

make_immediate_to_reg :: proc(s1: string, code: Transfer_Code, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = code,
		byte1 = Byte1{opcode = string(s1[0:4]), word_op = rune(s1[4])},
		byte2 = Byte2{reg = string(s1[5:8])},
		data = data,
	}
}

make_accumulator_immediate :: proc(s1: string, code: Transfer_Code, data: union {
		u8,
		u16,
	} = nil) -> ByteInstructions {
	return ByteInstructions {
		code = code,
		byte1 = Byte1{opcode = string(s1[0:7]), word_op = rune(s1[7])},
		byte2 = Byte2{reg = "000"},
		data = data,
	}
}

reg_assembly_data :: proc(data: union {
		u8,
		u16,
	}, w: rune) -> string {
	result: string


	switch w {
	case '1':
		switch d in data {
		case u8:
			result = fmt.tprintf("byte %d", transmute(i8)d)
		case u16:
			result = fmt.tprintf("word %d", transmute(i16)d)
		}
	case:
		result = fmt.tprintf("%d", data)
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

reg_assembly_instructions :: proc(bi: ByteInstructions) -> (ai: AssemblyInstructions, err: Error) {
	assembly_instruction := AssemblyInstructions {
		code      = bi.code,
		mod_field = bit_string_to_mod_field_code(bi.mod),
	}

	if direction, ok := bi.direction.?; ok {
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
			assembly_instruction.source = reg_assembly(bi.data, bi.word_op)
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
