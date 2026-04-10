package sim

import "core:fmt"

Error :: union {
	SharedErrors,
	DecodeErrors,
}


AssemblyInstructions :: struct {
	code : Transfer_Code,
	mod_field: Mod_Field_Code,
	source: string,
	destination: string,
	bytes_instruction: ByteInstructions
}


ai_write :: proc(ai: AssemblyInstructions, code: Transfer_Code) -> (s: string) {
	return fmt.tprintf("%s %s, %s", code, ai.destination, ai.source)
}

/*
Unified assembly instruction creation for all data transfer codes.
Routes through reg_assembly_instructions for reg/mem variants,
with special handling only for MOV's accumulator/memory variant.
*/
write_assembly_instructions :: proc(
	byte_instruction: ByteInstructions,
) -> (
	ai: AssemblyInstructions,
	err: Error,
) {
	// Only MOV has the accumulator/memory variant
	if byte_instruction.code == Data_Transfer_Code.MOV {
		switch _mov_bit_string_to_opt(byte_instruction.opcode) {
		case .ACCUMULATOR_MEMORY:
			return mov_mem_accumulator_instructions(byte_instruction, byte_instruction.opcode)
		case .REGMEM_WITH_REG, .IMMEDIATE_TO_REG_NO_MOD, .IMMEDIATE_TO_REGMEM:
			return reg_assembly_instructions(byte_instruction)
		case .UNDEFINED:
			return {}, .Invalid_Opcode
		case .IMMEDIATE_TO_ACCUMULATOR:
			return {}, .Invalid_Opcode
		}
	}

	return reg_assembly_instructions(byte_instruction)
}

write_from_byte_instructions :: proc(byte_instructions: [dynamic]ByteInstructions) -> (err: Error) {
	assembly_instructions : AssemblyInstructions

	for bi, i in byte_instructions {
		switch bi.code {
		case .MOV, .ADD, .SUB, .CMP:
			assembly_instructions = write_assembly_instructions(bi) or_return
			fmt.println(ai_write(assembly_instructions, bi.code))
		case .JNZ:
			fmt.printfln("%s %d", bi.code, bi.data)
		case .UNDEFINED:
			panic("Should have found an OpCode by now!")
		}

	}

	return nil
}

write_asm_from :: proc(byte_instructions: [dynamic]ByteInstructions) -> (ai: []AssemblyInstructions, err: Error){

	ai_i := make([]AssemblyInstructions, len(byte_instructions))
	defer delete(ai_i)

	for bi, i in byte_instructions {
		switch bi.code {
		case .MOV, .ADD, .SUB, .CMP:
			ai_i[i] = write_assembly_instructions(bi) or_return
			ai_i[i].bytes_instruction = bi
		case .JNZ:
			ai_i[i] = AssemblyInstructions{
				code = bi.code,
				bytes_instruction = bi,
			}
		case .UNDEFINED:
			panic("WTF Why Are You Here!")
		}

	}

	return ai_i, err
}


write_out_asm :: proc{
	write_from_byte_instructions,
}
