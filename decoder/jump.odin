package decoder

import "core:fmt"
jump_op_codes :: proc(s1 :string, dtc: ^Transfer_Code) {
	switch s1 {
	case "01110101": {dtc^ = .JNZ}
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
