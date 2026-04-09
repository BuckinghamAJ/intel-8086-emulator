package decoder

import "core:log"
import "core:fmt"
import "core:os"

Byte1 :: struct {
	opcode:    string,
	direction: Maybe(rune),
	word_op:   rune,
	sign_extension: Maybe(rune)
}

Byte2 :: struct {
	mod: string,
	reg: string,
	rm:  string,
}

Transfer_Code :: union {
	Data_Transfer_Code,
	Jump_Codes
}

Data_Transfer_Code :: enum {
	UNDEFINED,
	MOV,
	ADD,
	SUB,
	CMP,
}

Jump_Codes :: enum {
	JNZ,
}

ByteInstructions :: struct {
	code:         Transfer_Code,
	using byte1:  Byte1,
	using byte2:  Byte2,
	displacement: union {
		u8,
		u16,
	},
	data:         union {
		u8,
		u16,
	},
}

get_transfer_code :: proc(b1: u8, dtc: ^Transfer_Code) -> bool {
	switch {
	case (b1 & 0b11111100) == 0b10000000:
		return false
	}


	jump_op_codes(b1, dtc)
	mov_op_code_checks(b1, dtc)
	general_op_code_checks(b1, dtc)

	return true
}

read_binary_listing :: proc(path: string) -> (bi: [dynamic]ByteInstructions, err: os.Error) {
	data := os.read_entire_file(path, context.temp_allocator) or_return
	defer delete(data)


	instructions := make(
		[dynamic]ByteInstructions,
		0,
		len(data),
		allocator = context.temp_allocator,
	)

	fmt.println("Total bytes:", len(data))

	i := 0
	incr: int
	for {
		code: Transfer_Code

		incr = 0
		b1 := data[i]
		s1 := fmt.tprintf("%08b", b1)
		incr += 1
		log.debug("Processing byte: ", s1)
		if ok := get_transfer_code(b1, &code); !ok {
			s2 := fmt.tprintf("%08b", data[i+1])
			check_next_byte(s2, &code)
		}

		switch code {
		case .MOV:
			incr += decode_mov(s1, data, i, &instructions)
		case .ADD, .SUB, .CMP:
			incr += decode_instructions(s1, data, i, code, &instructions)
		case .JNZ:
			incr += decode_jump(s1, data, i, &instructions)
		case .UNDEFINED:
			panic(fmt.tprint("Undefined opcode for byte: ", s1))
		}


		i += incr

		if i >= len(data) {
			break
		}
	}

	return instructions, os.General_Error.None
}

entry :: proc(listing_path: string) {
	// fmt.println("Decoder entry point called with listing file: ", listing_path)

	instructions, err := read_binary_listing(listing_path)
	if err != os.General_Error.None {
		fmt.println("Error reading listing file: ", err)
		return
	}

	// fmt.printfln("ByteInstructions: %#v", instructions)
	log.debug("Successfully read binary listing. Total instructions: ", len(instructions))
	if err := write_asm(instructions); err != nil {
		errStr := fmt.tprintfln("There was an error in asm_write: %v", err)
		panic(errStr)
	}

}
