package decoder

import "core:fmt"
import "core:os"

DecodeError :: enum {
	None,
	FailedToReadFile,
}

Byte1 :: struct {
	opcode:    string,
	direction: rune,
	word_op:   rune,
}

Byte2 :: struct {
	mod: string,
	reg: string,
	rm:  string,
}

ByteInstructions :: struct {
	using byte1: Byte1,
	using byte2: Byte2,
}

to_byte1_from_byte :: proc(b1: byte) -> Byte1 {
	s1 := fmt.tprintf("%08b", b1)

	return Byte1{opcode = s1[0:6], direction = rune(s1[6]), word_op = rune(s1[7])}
}

to_byte1_from_string :: proc(s1: string) -> Byte1 {
	return Byte1{opcode = s1[0:6], direction = rune(s1[6]), word_op = rune(s1[7])}
}

to_byte1 :: proc{to_byte1_from_byte, to_byte1_from_string}

to_byte2_from_byte :: proc(b2: byte) -> Byte2 {
	s2 := fmt.tprintf("%08b", b2)

	return Byte2{mod = s2[0:2], reg = s2[2:5], rm = s2[5:8]}
}

to_byte2_from_string :: proc(s2: string) -> Byte2 {
	return Byte2{mod = s2[0:2], reg = s2[2:5], rm = s2[5:8]}
}

to_byte2 :: proc{to_byte2_from_byte, to_byte2_from_string}


read_binary_listing :: proc(path: string) -> (instructions: []ByteInstructions, err: os.Error) {
	data := os.read_entire_file(path, context.temp_allocator) or_return
	defer delete(data)

	instructions = make([]ByteInstructions, len(data) / 2)

	fmt.println("Total bytes:", len(data))

	for i := 0; i < len(data); i += 2 {
		lo := data[i]
		hi := data[i + 1]
		fmt.printf("pair[%d]: %08b %08b\n", i / 2, lo, hi)

		instructions[i / 2] = ByteInstructions{
			to_byte1(lo),
			to_byte2(hi),
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
