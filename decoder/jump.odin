package decoder

import "core:fmt"
jump_op_codes :: #force_inline proc(b1: u8, dtc: ^Transfer_Code) {
	switch b1 {
	case 0b01110101: {dtc^ = .JNZ}
	}
}

decode_jump :: proc(
	s1: string,
	data: []byte,
	i: int,
	instructions: ^[dynamic]ByteInstructions,
) -> (incr: int = 1) {

	append(
		instructions,
		ByteInstructions{
			code = .JNZ,
			data = u8(data[i+1])
		}
	)

	return
}
