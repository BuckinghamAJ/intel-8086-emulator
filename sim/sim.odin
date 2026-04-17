package sim

import "core:fmt"
import "core:log"
import "core:slice"
import "core:strings"

ORDERED_REG_KEYS :: [8]string{"AX", "BX", "CX", "DX", "SP", "BP", "SI", "DI"}
MEM_SIZE :: 1024 * 1024

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
	set_flags := make([dynamic]string, 9, allocator = context.temp_allocator)

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

	return fmt.tprintf("flags: %s->%s", strings.join(prior, ""), strings.join(after, ""))

}

handle_usigned_union :: proc(data: union {
		u8,
		u16,
	}) -> (d: u16) {
	switch d in data {
	case u8:
		return u16(d)
	case u16:
		return d
	}

	return 0
}

affected_register :: proc(ai: AssemblyInstructions) -> []string {
	bi := ai.bytes_instruction
	word_op := bi.word_op

	assert(word_op == '0' || word_op == '1', "Invalid word_op value. Expected '0' or '1'.")

	result := make([dynamic]string)

	switch bi.rm {
	case "000":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "AL")} else {append(&result, "AX")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "BX", "SI")
		case .UNDEFINED, nil:
			panic("WHY YOU HERE!")
		}
	case "001":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "CL")} else {append(&result, "CX")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "BX", "DI")
		case .UNDEFINED, nil:
			panic("Why are you here!")
		}
	case "010":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "DL")} else {append(&result, "DX")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "BP", "SI")
		case .UNDEFINED, nil:
			panic("Why are you here!")
		}
	case "011":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "BL")} else {append(&result, "BX")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "BP", "DI")
		case .UNDEFINED, nil:
			panic("Why are you here!")
		}
	case "100":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "AH")} else {append(&result, "SP")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "SI")
		case .UNDEFINED, nil:
			panic("Why are you here!")
		}
	case "101":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "CH")} else {append(&result, "BP")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "DI")
		case .UNDEFINED, nil:
			panic("Why are you here!")
		}
	case "110":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "DH")} else {append(&result, "SI")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "BP")
		case .UNDEFINED, nil:
			panic("Why are you here!")
		}
	case "111":
		switch ai.mod_field {
		case .REG_MODE:
			if word_op == '0' {append(&result, "BH")} else {append(&result, "DI")}
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			append(&result, "BX")
		case .UNDEFINED, nil:
			panic("Why are you here!")
		}
	}

	return result[:]
}

handle_register_mov :: proc(ai: AssemblyInstructions, register: ^map[string]u16, memory: ^[]u8) {
	prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])

	#partial switch ai.mod_field{
		case .REG_MODE:
			register[ai.destination] = register[ai.source] or_else handle_usigned_union(ai.bytes_instruction.data)
		case .MEMORY_MODE_NO_DISPLACEMENT, .MEMORY_MODE_8_BIT_DISPLACEMENT, .MEMORY_MODE_16_BIT_DISPLACEMENT:
			if is_reg_key(ai.source) {
				register[ai.destination] = register[ai.source]
			}
			regs_affected := affected_register(ai)
			defer delete(regs_affected)

			memory_idx := int(handle_usigned_union(ai.bytes_instruction.data))
			if len(regs_affected) > 0 {
				for reg, i in regs_affected{
					memory_idx += int(register[reg])
				}
			}

			register[ai.destination] = le_bytes_to_u16(memory[memory_idx], memory[memory_idx+1])
	}

	fmt.printf("%s->0x%x ", prior, register[ai.destination])
}



handle_register_with_flags :: proc(ai: AssemblyInstructions, flags: Flags, register: ^map[string]u16, memory: ^[]u8) {


}

handle_register :: proc {
	handle_register_mov,
	handle_register_with_flags,
}

store_u16_le :: proc(memory: ^[]u8, addr: int, v: u16) {
	assert(addr >= 0 && addr+1 < len(memory), "store_u16_le: out of bounds")

	lo := u8(v & 0x00FF)
	hi := u8((v >> 8) & 0x00FF)

	memory[addr] = lo
	memory[addr + 1] = hi
}

handle_memory :: proc(ai: AssemblyInstructions, register: ^map[string]u16, memory: ^[]u8) {
	// displacement := handle_usigned_union(ai.bytes_instruction.data)
	mem_idx := int(handle_usigned_union(ai.bytes_instruction.displacement))

	regs_affected := affected_register(ai)
	defer delete(regs_affected)

	for reg, i in regs_affected{
		mem_idx += int(register[reg])
	}

	store_u16_le(memory, mem_idx, register[ai.source] or_else handle_usigned_union(ai.bytes_instruction.data))

}

// TODO: Maybe add a cache to not loop each time.
is_reg_key :: proc(s: string) -> bool {
	for key in ORDERED_REG_KEYS {
		if s == key {
			return true
		}
	}
	return false
}

simulate :: proc(asm_instructions: []AssemblyInstructions) {
	flags := Flags{}
	register := make(map[string]u16)
	defer delete(register)

	ip_to_index: map[u16]int
	defer delete(ip_to_index)

	memory := make([]u8, MEM_SIZE) // 1MB of memory
	defer delete(memory)

	byte_offset: u16
	for ai, idx in asm_instructions {
		ip_to_index[byte_offset] = idx
		byte_offset += ai.bytes_instruction.size
	}

	ip: u16
	for ip_to_index[ip] < len(asm_instructions) {
		index, ok := ip_to_index[ip]
		if !ok {break}
		ai := asm_instructions[index]

		prior_ip := ip
		next_ip := ip + ai.bytes_instruction.size
		switch ai.code {
		case .MOV:
			if is_reg_key(ai.destination) { handle_register(ai, &register, &memory) }
			else {
				handle_memory(ai, &register, &memory)
			}

			fmt.printf("ip:0x%x->0x%x\n", prior_ip, next_ip)
		case .ADD:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])
			prior_flags := show_flags_set(flags)

			register[ai.destination] +=
				register[ai.source] or_else handle_usigned_union(ai.bytes_instruction.data)
			flags.CF = register[ai.destination] > 0xFFFF
			flags.ZF = register[ai.destination] == 0
			flags.SF = is_sign_bit_set(register[ai.destination])

			after_flags := show_flags_set(flags)

			fmt.printf("%s->0x%x ", prior, register[ai.destination])
			fmt.printf("ip:0x%x->0x%x ", prior_ip, next_ip)
			fmt.printf("%s\n", show_change_flags(prior_flags, after_flags))

		case .SUB:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])
			prior_flags := show_flags_set(flags)

			register[ai.destination] -=
				register[ai.source] or_else handle_usigned_union(ai.bytes_instruction.data)
			flags.CF = register[ai.destination] > 0xFFFF
			flags.ZF = register[ai.destination] == 0
			flags.SF = is_sign_bit_set(register[ai.destination])

			after_flags := show_flags_set(flags)

			fmt.printf("%s->0x%x ", prior, register[ai.destination])
			fmt.printf("ip:0x%x->0x%x ", prior_ip, next_ip)
			fmt.printf("%s\n", show_change_flags(prior_flags, after_flags))

		case .CMP:
			prior := fmt.tprintf("%s:0x%x", ai.destination, register[ai.destination])
			prior_flags := show_flags_set(flags)

			result :=
				register[ai.destination] -
				(register[ai.source] or_else handle_usigned_union(ai.bytes_instruction.data))
			flags.CF = result > 0xFFFF
			flags.ZF = result == 0
			flags.SF = is_sign_bit_set(result)

			after_flags := show_flags_set(flags)

			fmt.printfln("%s", show_change_flags(prior_flags, after_flags))
		case .JNZ:
			if !flags.ZF {
				disp := i16(cast(i8)(ai.bytes_instruction.data.(u8)))
				next_ip = u16(i16(next_ip) + disp)
			}

		}

		ip = next_ip
	}

	fmt.println("Final registers:")
	for key in ORDERED_REG_KEYS {
		v, ok := register[key]
		if !ok {
			continue
		}
		fmt.printfln("\t\t%s:0x%x (%d)", key, v, v)
	}
	fmt.printfln("\t\tip:0x%x (%d)", ip, ip)


	fmt.println("\tFlags:", strings.join(show_flags_set(flags), ""))
}
