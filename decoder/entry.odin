package decoder

import "core:log"
import "core:fmt"
import "core:os"
import "core:strings"

DecodeError :: enum {
	None,
	FailedToReadFile,
}

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

get_transfer_code :: proc(s1: string, dtc: ^Transfer_Code) -> bool {
	if ok := strings.has_prefix(s1, "100000"); ok {return false}


	jump_op_codes(s1, dtc)
	mov_op_code_checks(s1, dtc)
	add_sub_op_code_checks(s1, dtc)
	cmp_op_code_checks(s1, dtc)

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
	byte1: Byte1
	byte2: Byte2
	for {
		Transfer_Code: Transfer_Code

		incr = 0
		b1 := data[i]
		s1 := fmt.tprintf("%08b", b1)
		incr += 1
		log.debug("Processing byte: ", s1)
		if ok := get_transfer_code(s1, &Transfer_Code); !ok {
			s2 := fmt.tprintf("%08b", data[i+1])
			check_next_byte(s2, &Transfer_Code)
		}

		switch Transfer_Code {
		case .MOV:
			incr += decode_mov(s1, data, i, &instructions)
		case .ADD, .SUB:
			incr += decode_add_sub(s1, data, i, Transfer_Code, &instructions)
		case .CMP:
			incr += decode_cmp(s1, data, i, &instructions)
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
