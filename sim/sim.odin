package sim

import "core:fmt"

ORDERED_REG_KEYS :: [8]string{"AX", "BX", "CX", "DX", "SP", "BP", "SI", "DI"}

simulate :: proc(asm_instructions: []AssemblyInstructions){
	register := make(map[string]u16)
	defer delete(register)

	for ai, index in asm_instructions {
		switch ai.code {
		case .MOV:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])

			register[ai.destination] = register[ai.source] or_else ai.bytes_instruction.data.(u16)
			//ax:0x0->0x1
			fmt.printfln("%s->0x%x", prior, register[ai.destination])

		}
	}

	fmt.println("Final registers:")
	for key in ORDERED_REG_KEYS {
		v, ok := register[key]
		assert(ok, fmt.tprintf("Expected register %s to be initialized", key))
		fmt.printfln("\t\t%s:0x%x (%d)", key, v, v)
	}
}
