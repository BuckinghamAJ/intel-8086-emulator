package decoder

import "core:fmt"
Error :: enum {
	None,
	Invalid_Opcode,
	Invalid_Mod_Field_Code,
	Undefined_Memory_Mode,
	Error_Rm_Assembly
}

Opcode :: enum {
	UNDEFINED,
	MOV,
}

bit_string_to_opt :: proc(s: string) -> Opcode {
	switch s {
	case "100010": return .MOV
	}

	return .UNDEFINED
}

Mod_Field_Code :: enum {
	UNDEFINED,
	MEMORY_MODE_NO_DISPLACEMENT,
	MEMORY_MODE_8_BIT_DISPLACEMENT,
	MEMORY_MODE_16_BIT_DISPLACEMENT,
	REG_MODE,
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

// direction: 0 = reg is source, 1 = reg is destination

AssemblyInstructions :: struct {
	opcode: Opcode,
	mod_field: Mod_Field_Code,
	source: string,
	destination: string,
}

reg_assembly :: proc(reg: string, word_op: rune) -> string {
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

rm_assembly :: proc(rm: string, word_op: rune, mod: Mod_Field_Code) -> (s: string, err: Error) {
	assert(word_op == '0' || word_op == '1', "Invalid word_op value. Expected '0' or '1'.")

	switch rm {
	case "000":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "AL", .None} else {return "AX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "BX + SI" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "BX + SI + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "BX + SI + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "001":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "CL", .None} else {return "CX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "BX + DI" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "BX + DI + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "BX + DI + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "010":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "DL", .None} else {return "DX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "BP + SI" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "BP + SI + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "BP + SI + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "011":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "BL", .None} else {return "BX", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "BP + DI" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "BP + DI + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "BP + DI + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "100":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "AH", .None} else {return "SP", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "SI" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "SI + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "SI + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "101":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "CH", .None} else {return "BP", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "DI" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "DI + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "DI + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "110":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "DH", .None} else {return "SI", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "BP" , .None // TODO: Could be Wrong!
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "BP + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "BP + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	case "111":
		switch mod {
		case .REG_MODE:
			if word_op == '0' {return "BH", .None} else {return "DI", .None}
		case .MEMORY_MODE_NO_DISPLACEMENT:
			return "BX" , .None
		case .MEMORY_MODE_8_BIT_DISPLACEMENT:
			return "BX + D8", .None
		case .MEMORY_MODE_16_BIT_DISPLACEMENT:
			return "BX + D16", .None
		case .UNDEFINED:
			return "", .Undefined_Memory_Mode
		}
	}


	return "UNKNOWN", .Error_Rm_Assembly
}


create_assembly_instructions_from :: proc(byte_instructions: ByteInstructions) -> (ai: AssemblyInstructions, err: Error) {
	assembly_instruction := AssemblyInstructions{
		opcode = bit_string_to_opt(byte_instructions.byte1.opcode),
		mod_field = bit_string_to_mod_field_code(byte_instructions.byte2.mod),
	}

	switch byte_instructions.direction{
	case '0' :
		assembly_instruction.source = reg_assembly(byte_instructions.reg, byte_instructions.word_op)
		assembly_instruction.destination = rm_assembly(byte_instructions.rm,  byte_instructions.word_op, assembly_instruction.mod_field) or_return
	case '1' :
		assembly_instruction.source = rm_assembly(byte_instructions.rm,  byte_instructions.word_op, assembly_instruction.mod_field) or_return
		assembly_instruction.destination = reg_assembly(byte_instructions.reg, byte_instructions.word_op)
	}

	return assembly_instruction, .None

}

ai_write :: proc(ai: AssemblyInstructions) -> (s: string) {
	switch ai.opcode {
	case .MOV:
		return fmt.tprintf("MOV %s, %s", ai.destination, ai.source)
	case .UNDEFINED:
		return "UNDEFINED OPCODE"
	}
	return "UNKNOWN INSTRUCTION"
}

write_from_byte_instructions :: proc(byte_instructions: []ByteInstructions) -> (err: Error) {
	assembly_instructions := make([]AssemblyInstructions, len(byte_instructions), allocator = context.temp_allocator)

	for bi, i in byte_instructions {
		assembly_instructions[i] = create_assembly_instructions_from(bi) or_return
		fmt.println(ai_write(assembly_instructions[i]))
	}

	return .None
}

write_from_assemble_instructions :: proc(assembly_instructions: []AssemblyInstructions) -> (err: Error) {
	for ai in assembly_instructions {
		fmt.println(ai_write(ai))
	}

	return .None
}

asm_write :: proc{
	write_from_byte_instructions,
	write_from_assemble_instructions,
}
