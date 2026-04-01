package decoder

import "core:fmt"
Error :: enum {
	None,
	Invalid_Opcode,
	Invalid_Mod_Field_Code,
	Undefined_Memory_Mode,
	Error_Rm_Assembly
}

// direction: 0 = reg is source, 1 = reg is destination

AssemblyInstructions :: struct {
	code : Data_Transfer_Code,
	mod_field: Mod_Field_Code,
	source: string,
	destination: string,
}


ai_write :: proc(ai: AssemblyInstructions) -> (s: string) {
	switch ai.code {
	case .MOV:
		return fmt.tprintf("MOV %s, %s", ai.destination, ai.source)
	case .UNDEFINED:
		return "UNDEFINED OPCODE"
	}
	return "UNKNOWN INSTRUCTION"
}

write_from_byte_instructions :: proc(byte_instructions: [dynamic]ByteInstructions) -> (err: Error) {
	assembly_instructions := make([]AssemblyInstructions, len(byte_instructions), allocator = context.temp_allocator)

	for bi, i in byte_instructions {
		#partial switch bi.code {
		case .MOV:
			assembly_instructions[i] = mov_create_assembly_instructions_from(bi) or_return
		}
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
