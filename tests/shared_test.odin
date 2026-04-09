package tests

import "core:testing"
import "core:log"
import "core:fmt"
import "../decoder"

// ───────────────────────────────────────────────
// Unit tests: check_next_byte
// ───────────────────────────────────────────────

@(test)
test_check_next_byte :: proc(t: ^testing.T) {
	log.info("test_check_next_byte...")

	test_cases := []struct {
		// byte2 bit string where bits [2:5] identify ADD/SUB/CMP
		byte2:    string,
		expected: decoder.Transfer_Code,
	}{
		// bits [2:5] = "000" -> ADD
		{"00000000", decoder.Data_Transfer_Code.ADD},
		// bits [2:5] = "101" -> SUB
		{"00101000", decoder.Data_Transfer_Code.SUB},
		// bits [2:5] = "111" -> CMP
		{"00111000", decoder.Data_Transfer_Code.CMP},
	}

	for tc in test_cases {
		code: decoder.Transfer_Code
		decoder.check_next_byte(tc.byte2, &code)
		testing.expectf(t, code == tc.expected,
			"check_next_byte(%s): got %v, expected %v", tc.byte2, code, tc.expected)
	}
}

// ───────────────────────────────────────────────
// Unit tests: bit_string_to_mod_field_code
// ───────────────────────────────────────────────

@(test)
test_bit_string_to_mod_field_code :: proc(t: ^testing.T) {
	log.info("test_bit_string_to_mod_field_code...")

	test_cases := []struct {
		input:    string,
		expected: decoder.Mod_Field_Code,
	}{
		{"00", .MEMORY_MODE_NO_DISPLACEMENT},
		{"01", .MEMORY_MODE_8_BIT_DISPLACEMENT},
		{"10", .MEMORY_MODE_16_BIT_DISPLACEMENT},
		{"11", .REG_MODE},
		{"XX", .UNDEFINED},
	}

	for tc in test_cases {
		result := decoder.bit_string_to_mod_field_code(tc.input)
		testing.expectf(t, result == tc.expected,
			"bit_string_to_mod_field_code(%s): got %v, expected %v", tc.input, result, tc.expected)
	}
}

// ───────────────────────────────────────────────
// Unit tests: reg_assembly_data
// ───────────────────────────────────────────────

@(test)
test_reg_assembly_data :: proc(t: ^testing.T) {
	log.info("test_reg_assembly_data...")

	// u8 value
	{
		u8v := u8(42)
		result := decoder.reg_assembly(u8v)
		testing.expectf(t, result == "42",
			"reg_assembly_data(u8(42)): got %s, expected 42", result)
	}

	// u16 value
	{
		u16v := u16(1000)
		result := decoder.reg_assembly(u16v)
		testing.expectf(t, result == "1000",
			"reg_assembly_data(u16(1000)): got %s, expected 1000", result)
	}

	// nil -> "0"
	{
		data: union { u8, u16 }
		result := decoder.reg_assembly(data)
		testing.expectf(t, result == "0",
			"reg_assembly_data(nil): got %s, expected 0", result)
	}

	// negative u8 (signed interpretation via transmute)
	{
		u8v := u8(0xFF)
		result := decoder.reg_assembly(u8v)
		testing.expectf(t, result == "-1",
			"reg_assembly_data(u8(0xFF)): got %s, expected -1", result)
	}

	// negative u16
	{
		u16v := u16(0xFFFF)
		result := decoder.reg_assembly(u16v)
		testing.expectf(t, result == "-1",
			"reg_assembly_data(u16(0xFFFF)): got %s, expected -1", result)
	}
}

// ───────────────────────────────────────────────
// Unit tests: memory_size_prefix
// ───────────────────────────────────────────────

@(test)
test_memory_size_prefix :: proc(t: ^testing.T) {
	log.info("test_memory_size_prefix...")

	result_byte := decoder.memory_size_prefix('0')
	testing.expectf(t, result_byte == "byte",
		"memory_size_prefix('0'): got %s, expected byte", result_byte)

	result_word := decoder.memory_size_prefix('1')
	testing.expectf(t, result_word == "word",
		"memory_size_prefix('1'): got %s, expected word", result_word)
}

// ───────────────────────────────────────────────
// Unit tests: make_reg_to_reg
// ───────────────────────────────────────────────

@(test)
test_make_reg_to_reg :: proc(t: ^testing.T) {
	log.info("test_make_reg_to_reg...")

	// s1 = "10001001" -> opcode=s1[0:6]="100010", direction=s1[6]='0', word_op=s1[7]='1'
	// s2 = "11000001" -> mod=s2[0:2]="11", reg=s2[2:5]="000", rm=s2[5:8]="001"
	bi := decoder.make_reg_to_reg("10001001", "11000001", decoder.Data_Transfer_Code.MOV)

	testing.expectf(t, bi.opcode == "100010", "opcode: got %s, expected 100010", bi.opcode)
	d, d_ok := bi.direction.?
	testing.expect(t, d_ok, "direction should be set")
	testing.expectf(t, d == '0', "direction: got %c, expected '0'", d)
	testing.expectf(t, bi.word_op == '1', "word_op: got %c, expected '1'", bi.word_op)
	testing.expectf(t, bi.mod == "11", "mod: got %s, expected 11", bi.mod)
	testing.expectf(t, bi.reg == "000", "reg: got %s, expected 000", bi.reg)
	testing.expectf(t, bi.rm == "001", "rm: got %s, expected 001", bi.rm)
	testing.expectf(t, bi.code == decoder.Data_Transfer_Code.MOV, "code: got %v, expected MOV", bi.code)

	// With displacement
	bi2 := decoder.make_reg_to_reg("10001001", "01000001", decoder.Data_Transfer_Code.ADD, displacement = u8(5))
	_, disp_ok := bi2.displacement.(u8)
	testing.expect(t, disp_ok, "displacement should be u8")
	testing.expectf(t, bi2.displacement.(u8) == 5, "displacement: got %v, expected 5", bi2.displacement)
}

// ───────────────────────────────────────────────
// Unit tests: make_immediate_with_mod
// ───────────────────────────────────────────────

@(test)
test_make_immediate_with_mod :: proc(t: ^testing.T) {
	log.info("test_make_immediate_with_mod...")

	// s1 = "10000011" -> opcode=s1[0:7]="1000001", sign_extension=s1[6]='1', word_op=s1[7]='1'
	// s2 = "11000001" -> mod=s2[0:2]="11", rm=s2[5:8]="001"
	bi := decoder.make_immediate_with_mod("10000011", "11000001", decoder.Data_Transfer_Code.ADD, data = u8(10))

	testing.expectf(t, bi.opcode == "1000001", "opcode: got %s, expected 1000001", bi.opcode)
	se, se_ok := bi.sign_extension.?
	testing.expect(t, se_ok, "sign_extension should be set")
	testing.expectf(t, se == '1', "sign_extension: got %c, expected '1'", se)
	testing.expectf(t, bi.word_op == '1', "word_op: got %c, expected '1'", bi.word_op)
	testing.expectf(t, bi.mod == "11", "mod: got %s, expected 11", bi.mod)
	testing.expectf(t, bi.rm == "001", "rm: got %s, expected 001", bi.rm)
	testing.expectf(t, bi.data.(u8) == 10, "data: got %v, expected 10", bi.data)
}

// ───────────────────────────────────────────────
// Unit tests: make_immediate_to_reg
// ───────────────────────────────────────────────

@(test)
test_make_immediate_to_reg :: proc(t: ^testing.T) {
	log.info("test_make_immediate_to_reg...")

	// s1 = "10110001" -> opcode=s1[0:4]="1011", word_op=s1[4]='0', reg=s1[5:8]="001"
	bi := decoder.make_immediate_to_reg("10110001", decoder.Data_Transfer_Code.MOV, data = u8(7))

	testing.expectf(t, bi.opcode == "1011", "opcode: got %s, expected 1011", bi.opcode)
	testing.expectf(t, bi.word_op == '0', "word_op: got %c, expected '0'", bi.word_op)
	testing.expectf(t, bi.reg == "001", "reg: got %s, expected 001", bi.reg)
	testing.expectf(t, bi.data.(u8) == 7, "data: got %v, expected 7", bi.data)
}

// ───────────────────────────────────────────────
// Unit tests: make_accumulator_immediate
// ───────────────────────────────────────────────

@(test)
test_make_accumulator_immediate :: proc(t: ^testing.T) {
	log.info("test_make_accumulator_immediate...")

	// s1 = "00000100" -> opcode=s1[0:7]="0000010", word_op=s1[7]='0'
	bi := decoder.make_accumulator_immediate("00000100", decoder.Data_Transfer_Code.ADD, data = u8(5))

	testing.expectf(t, bi.opcode == "0000010", "opcode: got %s, expected 0000010", bi.opcode)
	testing.expectf(t, bi.word_op == '0', "word_op: got %c, expected '0'", bi.word_op)
	testing.expectf(t, bi.reg == "000", "reg: got %s, expected 000", bi.reg)
	testing.expectf(t, bi.data.(u8) == 5, "data: got %v, expected 5", bi.data)
}

// ───────────────────────────────────────────────
// Integration tests: reg_assembly_instructions
// ───────────────────────────────────────────────

@(test)
test_reg_assembly_instructions_direction_0 :: proc(t: ^testing.T) {
	log.info("test_reg_assembly_instructions_direction_0...")

	// direction='0': reg -> source, rm -> destination
	// MOV CX, AX  =>  direction=0, word_op=1, reg="000"(AX), rm="001"(CX), mod="11"(REG_MODE)
	bi := decoder.ByteInstructions{
		code = decoder.Data_Transfer_Code.MOV,
		byte1 = decoder.Byte1{ opcode = "100010", direction = '0', word_op = '1' },
		byte2 = decoder.Byte2{ mod = "11", reg = "000", rm = "001" },
	}

	ai, err := decoder.reg_assembly_instructions(bi)
	testing.expect(t, err == nil, "expected no error")
	testing.expectf(t, ai.source == "AX", "source: got %s, expected AX", ai.source)
	testing.expectf(t, ai.destination == "CX", "destination: got %s, expected CX", ai.destination)
}

@(test)
test_reg_assembly_instructions_direction_1 :: proc(t: ^testing.T) {
	log.info("test_reg_assembly_instructions_direction_1...")

	// direction='1': rm -> source, reg -> destination
	// MOV AX, CX  =>  direction=1, word_op=1, reg="000"(AX), rm="001"(CX), mod="11"(REG_MODE)
	bi := decoder.ByteInstructions{
		code = decoder.Data_Transfer_Code.MOV,
		byte1 = decoder.Byte1{ opcode = "100010", direction = '1', word_op = '1' },
		byte2 = decoder.Byte2{ mod = "11", reg = "000", rm = "001" },
	}

	ai, err := decoder.reg_assembly_instructions(bi)
	testing.expect(t, err == nil, "expected no error")
	testing.expectf(t, ai.source == "CX", "source: got %s, expected CX", ai.source)
	testing.expectf(t, ai.destination == "AX", "destination: got %s, expected AX", ai.destination)
}

@(test)
test_reg_assembly_instructions_no_direction_rm_reg_mode :: proc(t: ^testing.T) {
	log.info("test_reg_assembly_instructions_no_direction_rm_reg_mode...")

	// No direction, rm set, mod=REG_MODE -> destination = rm_operand (no size prefix)
	// e.g. MOV CX, 12
	bi := decoder.ByteInstructions{
		code = decoder.Data_Transfer_Code.MOV,
		byte1 = decoder.Byte1{ opcode = "1100011", word_op = '1' },
		byte2 = decoder.Byte2{ mod = "11", rm = "001" },
		data = u16(12),
	}

	ai, err := decoder.reg_assembly_instructions(bi)
	testing.expect(t, err == nil, "expected no error")
	testing.expectf(t, ai.destination == "CX", "destination: got %s, expected CX", ai.destination)
	testing.expectf(t, ai.source == "12", "source: got %s, expected 12", ai.source)
}

@(test)
test_reg_assembly_instructions_no_direction_rm_memory :: proc(t: ^testing.T) {
	log.info("test_reg_assembly_instructions_no_direction_rm_memory...")

	// No direction, rm set, mod=MEMORY_MODE_NO_DISPLACEMENT -> destination = "word [BX + SI]"
	bi := decoder.ByteInstructions{
		code = decoder.Data_Transfer_Code.MOV,
		byte1 = decoder.Byte1{ opcode = "1100011", word_op = '1' },
		byte2 = decoder.Byte2{ mod = "00", rm = "000" },
		data = u16(100),
	}

	ai, err := decoder.reg_assembly_instructions(bi)
	testing.expect(t, err == nil, "expected no error")
	testing.expectf(t, ai.destination == "word [BX + SI]",
		"destination: got %s, expected 'word [BX + SI]'", ai.destination)
	testing.expectf(t, ai.source == "100", "source: got %s, expected 100", ai.source)
}

@(test)
test_reg_assembly_instructions_no_direction_no_rm :: proc(t: ^testing.T) {
	log.info("test_reg_assembly_instructions_no_direction_no_rm...")

	// No direction, no rm (empty string) -> destination = reg_assembly(reg, word_op), source = reg_assembly(data)
	// e.g. MOV CL, 12  via make_immediate_to_reg path
	bi := decoder.ByteInstructions{
		code = decoder.Data_Transfer_Code.MOV,
		byte1 = decoder.Byte1{ opcode = "1011", word_op = '0' },
		byte2 = decoder.Byte2{ reg = "001" },
		data = u8(12),
	}

	ai, err := decoder.reg_assembly_instructions(bi)
	testing.expect(t, err == nil, "expected no error")
	testing.expectf(t, ai.destination == "CL", "destination: got %s, expected CL", ai.destination)
	testing.expectf(t, ai.source == "12", "source: got %s, expected 12", ai.source)
}
