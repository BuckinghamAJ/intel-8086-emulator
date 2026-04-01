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
			// TODO: Move inside the mov.odin file and make it more modular
			switch bit_string_to_opt(s1) {
			case .REGISTER_TO_REGISTER:
				s2 := fmt.tprintf("%08b", data[i + 1])
				incr += 1

				switch bit_string_to_mod_field_code(string(s2[0:2])) {
				case .REG_MODE:
					append(&instructions, mov_register_mode(s1, s2))
				case .MEMORY_MODE_NO_DISPLACEMENT:
					if string(s2[5:8]) == "110" {
						append(
							&instructions,
							mov_memory_no_displacement(
								s1,
								s2,
								(u16(data[i + 3]) << 8) | u16(data[i + 2]),
							),
						)
						incr += 2
					} else {
						append(&instructions, mov_memory_no_displacement(s1, s2))
					}
				case .MEMORY_MODE_8_BIT_DISPLACEMENT:
					append(&instructions, mov_memory_mode_displacement(s1, s2, u8(data[i + 2])))
					incr += 1
				case .MEMORY_MODE_16_BIT_DISPLACEMENT:
					append(
						&instructions,
						mov_memory_mode_displacement(
							s1,
							s2,
							(u16(data[i + 3]) << 8) | u16(data[i + 2]),
						),
					)
					incr += 2
				case .UNDEFINED:
					msg := fmt.tprint(
						"Undefined Mod_Field_Code for instruction with bytes: ",
						s1,
						s2,
					)
					panic(msg)
				}
			case .IMMEDIATE_TO_REG_NO_DISP:
				switch s1[4] {
				case '0':
					b2 := data[i + 1]
					incr += 1
					append(&instructions, mov_immediate_to_register(s1, u8(b2)))
				case '1':
					b2 := data[i + 1]
					b3 := data[i + 2]
					incr += 2

					append(&instructions, mov_immediate_to_register(s1, (u16(b3) << 8) | u16(b2)))
				}
			case .IMMEDIATE_TO_REG_DISP:
				s2 := fmt.tprintf("%08b", data[i + 1])
				incr += 1

				switch bit_string_to_mod_field_code(string(s2[0:2])) {
				case .REG_MODE:
					switch s1[7] {
					case '0':
						b3 := data[i + 2]
						incr += 1
						append(&instructions, mov_register_mode(s1, s2, u8(b3)))
					case '1':
						b3 := data[i + 2]
						b4 := data[i + 3]
						incr += 2
						append(&instructions, mov_register_mode(s1, s2, (u16(b4) << 8) | u16(b3)))

					}
				case .MEMORY_MODE_NO_DISPLACEMENT:
					if string(s2[5:8]) == "110" {

						switch s1[7] {
						case '0':
							append(
								&instructions,
								mov_memory_no_displacement(
									s1,
									s2,
									(u16(data[i + 3]) << 8) | u16(data[i + 2]),
									u8(data[i + 4]),
								),
							)
							incr += 3
						case '1':
							append(
								&instructions,
								mov_memory_no_displacement(
									s1,
									s2,
									(u16(data[i + 3]) << 8) | u16(data[i + 2]),
									(u16(data[i + 5]) << 8) | u16(data[i + 4]),
								),
							)
							incr += 4
						}
					} else {
						switch s1[7] {
						case '0':
							append(
								&instructions,
								mov_memory_no_disp_with_data(s1, s2, u8(data[i + 2])),
							)
							incr += 1
						case '1':
							append(
								&instructions,
								mov_memory_no_disp_with_data(
									s1,
									s2,
									(u16(data[i + 3]) << 8) | u16(data[i + 2]),
								),
							)
							incr += 2
						}
					}
				case .MEMORY_MODE_8_BIT_DISPLACEMENT:
					switch s1[7] {
					case '0':
						append(
							&instructions,
							mov_memory_mode_displacement(s1, s2, u8(data[i + 2]), u8(data[i + 3])),
						)
						incr += 2
					case '1':
						append(
							&instructions,
							mov_memory_mode_displacement(
								s1,
								s2,
								u8(data[i + 2]),
								(u16(data[i + 4]) << 8) | u16(data[i + 3]),
							),
						)
						incr += 3

					}
				case .MEMORY_MODE_16_BIT_DISPLACEMENT:
					switch s1[7] {
					case '0':
						append(
							&instructions,
							mov_memory_mode_displacement(
								s1,
								s2,
								(u16(data[i + 3]) << 8) | u16(data[i + 2]),
								u8(data[i + 4]),
							),
						)
						incr += 3
					case '1':
						append(
							&instructions,
							mov_memory_mode_displacement(
								s1,
								s2,
								(u16(data[i + 3]) << 8) | u16(data[i + 2]),
								(u16(data[i + 5]) << 8) | u16(data[i + 4]),
							),
						)
						incr += 4
					}
				case .UNDEFINED:
					msg := fmt.tprint(
						"Undefined Mod_Field_Code for instruction with bytes: ",
						s1,
						s2,
					)
					panic(msg)
				}
			case .UNDEFINED:
				msg := fmt.tprint("Undefined opcode for byte: ", s1)
				panic(msg)
			}
		case .UNDEFINED:
	 		panic(fmt.tprint("Undefined opcode for byte: ", s1))
		}


		i += incr + 1

		if i + 1 >= len(data) {
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
