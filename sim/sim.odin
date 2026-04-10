package sim

import "core:fmt"
import "core:log"
import "core:slice"
import "core:strings"

ORDERED_REG_KEYS :: [8]string{"AX", "BX", "CX", "DX", "SP", "BP", "SI", "DI"}

Flags :: struct {
	CF: bool, // Carry Flag
	PF: bool, // Parity Flag
	AF: bool, // Auxiliary Carry Flag
	ZF: bool, // Zero Flag
	SF: bool, // Sign Flag
	TF: bool, // Trap Flag
	IF: bool, // Interrupt Enable Flag
	DF: bool, // Direction Flag
	OF: bool, // Overflow Flag
}

Flag_Keys :: [9]string{"CF", "PF", "AF", "ZF", "SF", "TF", "IF", "DF", "OF"}

//0x8000 (checking the sign bit) Need to be data & 0x8000 != 0 to set the sign flag

is_sign_bit_set :: proc(data: u16) -> bool {
	return (data & 0x8000) != 0
}

show_flags_set :: proc(f: Flags) -> []string {
	set_flags:= make([dynamic]string, 9, allocator = context.temp_allocator)

	if f.CF {
		append(&set_flags, "C")
	}
	if f.PF {
		append(&set_flags, "P")
	}
	if f.AF {
		append(&set_flags, "A")
	}
	if f.ZF {
		append(&set_flags, "Z")
	}
	if f.SF {
		append(&set_flags, "S")
	}
	if f.TF {
		append(&set_flags, "T")
	}
	if f.IF {
		append(&set_flags, "I")
	}
	if f.DF {
		append(&set_flags, "D")
	}
	if f.OF {
		append(&set_flags, "O")
	}

	// log.debug("Current flags set: ", set_flags[:])

	return set_flags[:]
}

show_change_flags :: proc(prior: []string, after: []string) -> string {
	if len(prior) == 0 && len(after) == 0 {
		return ""
	}

	if slice.equal(prior, after) {
		return ""
	}

	// log.debug("Prior flags: ", prior)
	// log.debug("After flags: ", after)

	return fmt.tprintf("flags: %s->%s", strings.join(prior, ""), strings.join(after, ""))

}

simulate :: proc(asm_instructions: []AssemblyInstructions) {
	flags := Flags{}

	register := make(map[string]u16)
	defer delete(register)

	for ai, index in asm_instructions {
		switch ai.code {
		case .MOV:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])

			register[ai.destination] = register[ai.source] or_else ai.bytes_instruction.data.(u16)
			//ax:0x0->0x1
			fmt.printfln("%s->0x%x", prior, register[ai.destination])
		case .ADD:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])
			prior_flags := show_flags_set(flags)

			register[ai.destination] += register[ai.source] or_else ai.bytes_instruction.data.(u16)
			flags.CF = register[ai.destination] > 0xFFFF
			flags.ZF = register[ai.destination] == 0
			flags.SF = is_sign_bit_set(register[ai.destination])

			after_flags := show_flags_set(flags)

			fmt.printfln(
				"%s->0x%x; %s",
				prior,
				register[ai.destination],
				show_change_flags(prior_flags, after_flags),
			)
		case .SUB:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])
			prior_flags := show_flags_set(flags)

			register[ai.destination] -= register[ai.source] or_else ai.bytes_instruction.data.(u16)
			flags.CF = register[ai.destination] > 0xFFFF
			flags.ZF = register[ai.destination] == 0
			flags.SF = is_sign_bit_set(register[ai.destination])

			after_flags := show_flags_set(flags)

			fmt.printfln(
				"%s->0x%x; %s",
				prior,
				register[ai.destination],
				show_change_flags(prior_flags, after_flags),
			)
		case .CMP:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])
			prior_flags := show_flags_set(flags)

			result := register[ai.destination] - (register[ai.source] or_else ai.bytes_instruction.data.(u16))
			flags.CF = result > 0xFFFF
			flags.ZF = result == 0
			flags.SF = is_sign_bit_set(result)

			after_flags := show_flags_set(flags)

			fmt.printfln(
				"%s",
				show_change_flags(prior_flags, after_flags),
			)

		}
	}

	fmt.println("Final registers:")
	for key in ORDERED_REG_KEYS {
		v, ok := register[key];
		if !ok{
			continue
		}
		fmt.printfln("\t\t%s:0x%x (%d)", key, v, v)
	}
}
