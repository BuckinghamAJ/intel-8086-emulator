package decoder

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
}

Byte2 :: struct {
	mod: string,
	reg: string,
	rm:  string,
}

Data_Transfer_Code :: enum {
	UNDEFINED,
	MOV,
}

ByteInstructions :: struct {
	code:         Data_Transfer_Code,
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
	method_name:  string,
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
	defer delete(instructions)

	fmt.println("Total bytes:", len(data))

	i := 0
	incr: int
	byte1: Byte1
	byte2: Byte2
	data_transfer_code: Data_Transfer_Code
	for {

		incr = 0
		b1 := data[i]
		s1 := fmt.tprintf("%08b", b1)
		fmt.println("Processing byte: ", s1)
		if ok := strings.has_prefix(s1, "1100011"); ok {data_transfer_code = .MOV}
		if ok := strings.has_prefix(s1, "11011"); ok {data_transfer_code = .MOV}
		if ok := strings.has_prefix(s1, "100010"); ok {data_transfer_code = .MOV}

		switch data_transfer_code {
		case .MOV:
			incr += decode_mov(s1, data, i, &instructions)
		case .UNDEFINED:
	 		panic(fmt.tprint("Undefined opcode for byte: ", s1))
		}


		i += incr + 1

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
	fmt.println("Successfully read binary listing. Total instructions:", len(instructions))
	asm_write(instructions)

}
