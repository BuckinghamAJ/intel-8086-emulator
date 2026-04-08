package decoder

import "core:fmt"

SharedErrors :: enum {
	None,
	Invalid_Opcode,
}

Error :: union {
	SharedErrors,
	Mov_Errors,
}


AssemblyInstructions :: struct {
	code : Transfer_Code,
	mod_field: Mod_Field_Code,
	source: string,
	destination: string,
}


ai_write :: proc(ai: AssemblyInstructions, code: Transfer_Code) -> (s: string) {
	return fmt.tprintf("%s %s, %s", code, ai.destination, ai.source)
}

write_from_byte_instructions :: proc(byte_instructions: [dynamic]ByteInstructions) -> (err: Error) {
	assembly_instructions : AssemblyInstructions

	for bi, i in byte_instructions {
		switch bi.code {
		case .MOV:
			assembly_instructions = mov_create_assembly_instructions_from(bi) or_return
			fmt.println(ai_write(assembly_instructions, bi.code))

		case .ADD, .SUB, .CMP:
			assembly_instructions = reg_assembly_instructions(bi) or_return
			fmt.println(ai_write(assembly_instructions, bi.code))
		case .JNZ:
			fmt.printfln("%s %d", bi.code, bi.data)
		case .UNDEFINED:
			panic("Should Of found an OpCode by now!")
		}

	}


	return nil
}

write_from_assemble_instructions :: proc(assembly_instructions: []AssemblyInstructions) -> (err: Error) {
	for ai in assembly_instructions {
		fmt.println(ai_write(ai, ai.code))
	}

	return nil
}

write_asm :: proc{
	write_from_byte_instructions,
	write_from_assemble_instructions,
}
