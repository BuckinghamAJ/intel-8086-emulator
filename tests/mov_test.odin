package tests

import "core:testing"
import "core:log"
import "../sim"

@(test)
test_reg_assembly_all_registers :: proc(t: ^testing.T) {
	log.info("test_reg_assembly_all_registers...")

	test_cases := []struct {
		reg:      string,
		word_op:  rune,
		expected: string,
	}{
		{"000", '0', "AL"},
		{"000", '1', "AX"},
		{"001", '0', "CL"},
		{"001", '1', "CX"},
		{"010", '0', "DL"},
		{"010", '1', "DX"},
		{"011", '0', "BL"},
		{"011", '1', "BX"},
		{"100", '0', "AH"},
		{"100", '1', "SP"},
		{"101", '0', "CH"},
		{"101", '1', "BP"},
		{"110", '0', "DH"},
		{"110", '1', "SI"},
		{"111", '0', "BH"},
		{"111", '1', "DI"},
	}

	for tc in test_cases {
		result := sim.reg_assembly(tc.reg, tc.word_op)
		testing.expectf(t, result == tc.expected,
			"reg_assembly(%s,%c): got %s expected %s",
			tc.reg,
			tc.word_op,
			result,
			tc.expected,
		)
	}
}

@(test)
test_rm_assembly_reg_mode_all_registers :: proc(t: ^testing.T) {
	log.info("test_rm_assembly_reg_mode_all_registers...")

	test_cases := []struct {
		rm:       string,
		word_op:  rune,
		expected: string,
	}{
		{"000", '0', "AL"},
		{"000", '1', "AX"},
		{"001", '0', "CL"},
		{"001", '1', "CX"},
		{"010", '0', "DL"},
		{"010", '1', "DX"},
		{"011", '0', "BL"},
		{"011", '1', "BX"},
		{"100", '0', "AH"},
		{"100", '1', "SP"},
		{"101", '0', "CH"},
		{"101", '1', "BP"},
		{"110", '0', "DH"},
		{"110", '1', "SI"},
		{"111", '0', "BH"},
		{"111", '1', "DI"},
	}

	for tc in test_cases {
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = tc.word_op },
			byte2 = sim.Byte2{ rm = tc.rm },
		}

		result, err := sim.rm_assembly(bi, .REG_MODE)
		testing.expect(t, err == nil)
		testing.expectf(t, result == tc.expected,
			"rm_assembly(%s,%c,REG): got %s expected %s",
			tc.rm,
			tc.word_op,
			result,
			tc.expected,
		)
	}
}

@(test)
test_rm_assembly_memory_modes :: proc(t: ^testing.T) {
	log.info("test_rm_assembly_memory_modes...")

	base_cases := []struct {
		rm:       string,
		expected: string,
	}{
		{"000", "[BX + SI]"},
		{"001", "[BX + DI]"},
		{"010", "[BP + SI]"},
		{"011", "[BP + DI]"},
		{"100", "[SI]"},
		{"101", "[DI]"},
		{"111", "[BX]"},
	}

	for tc in base_cases {
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = tc.rm },
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_NO_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expectf(t, result == tc.expected,
			"rm_assembly(%s,NO_DISP): got %s expected %s", tc.rm, result, tc.expected)
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ direction = '0', word_op = '1' },
			byte2 = sim.Byte2{ rm = "110" },
			data  = u16(4660),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_NO_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[4660]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "110" },
			displacement = u16(4660),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_NO_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[4660]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "110" },
			displacement = u8(0),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_8_BIT_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[BP]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "110" },
			displacement = u8(5),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_8_BIT_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[BP + 5]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "110" },
			displacement = u16(0),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_16_BIT_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[BP]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "110" },
			displacement = u16(300),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_16_BIT_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[BP + 300]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "000" },
			displacement = u8(7),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_8_BIT_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[BX + SI + 7]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "001" },
			displacement = u16(260),
		}

		result, err := sim.rm_assembly(bi, .MEMORY_MODE_16_BIT_DISPLACEMENT)
		testing.expect(t, err == nil)
		testing.expect(t, result == "[BX + DI + 260]")
	}

	{
		bi := sim.ByteInstructions{
			byte1 = sim.Byte1{ word_op = '1' },
			byte2 = sim.Byte2{ rm = "000" },
		}

		_, err := sim.rm_assembly(bi, .UNDEFINED)
		testing.expect(t, err == sim.DecodeErrors.Undefined_Memory_Mode)
	}
}

@(test)
test_mov_bit_string_to_opt :: proc(t: ^testing.T) {
	log.info("test_mov_bit_string_to_opt...")

	test_cases := []struct {
		input:    string,
		expected: sim.Opcode_Variant,
	}{
		{"10110000", .IMMEDIATE_TO_REG_NO_MOD},
		{"11000110", .IMMEDIATE_TO_REGMEM},
		{"10001001", .REGMEM_WITH_REG},
		{"10100000", .ACCUMULATOR_MEMORY},
		{"00000000", .UNDEFINED},
	}

	for tc in test_cases {
		result := sim._mov_bit_string_to_opt(tc.input)
		testing.expectf(t, result == tc.expected,
			"_mov_bit_string_to_opt(%s): got %v expected %v", tc.input, result, tc.expected)
	}
}

@(test)
test_decode_mov_regmem_with_reg :: proc(t: ^testing.T) {
	log.info("test_decode_mov_regmem_with_reg...")

	data := []byte{0x89, 0xC1}
	instructions := make([dynamic]sim.ByteInstructions, 0, 1)
	defer delete(instructions)

	incr := sim.decode_mov("10001001", data, 0, &instructions)
	testing.expect(t, incr == 1)
	testing.expect(t, len(instructions) == 1)

	bi := instructions[0]
	testing.expect(t, bi.code == sim.Data_Transfer_Code.MOV)
	testing.expect(t, bi.opcode == "100010")
	d, ok := bi.direction.?
	testing.expect(t, ok)
	testing.expect(t, d == '0')
	testing.expect(t, bi.word_op == '1')
	testing.expect(t, bi.mod == "11")
	testing.expect(t, bi.reg == "000")
	testing.expect(t, bi.rm == "001")

	ai, err := sim.write_assembly_instructions(bi)
	testing.expect(t, err == nil)
	testing.expect(t, ai.destination == "CX")
	testing.expect(t, ai.source == "AX")
}

@(test)
test_decode_mov_regmem_with_reg_bp_zero_disp8 :: proc(t: ^testing.T) {
	log.info("test_decode_mov_regmem_with_reg_bp_zero_disp8...")

	data := []byte{0x8B, 0x46, 0x00}
	instructions := make([dynamic]sim.ByteInstructions, 0, 1)
	defer delete(instructions)

	incr := sim.decode_mov("10001011", data, 0, &instructions)
	testing.expect(t, incr == 2)
	testing.expect(t, len(instructions) == 1)

	bi := instructions[0]
	d, ok := bi.direction.?
	testing.expect(t, ok)
	testing.expect(t, d == '1')
	testing.expect(t, bi.mod == "01")
	testing.expect(t, bi.rm == "110")
	testing.expect(t, bi.displacement.(u8) == 0)

	ai, err := sim.write_assembly_instructions(bi)
	testing.expect(t, err == nil)
	testing.expect(t, ai.destination == "AX")
	testing.expect(t, ai.source == "[BP]")
}

@(test)
test_decode_mov_immediate_to_reg :: proc(t: ^testing.T) {
	log.info("test_decode_mov_immediate_to_reg...")

	{
		data := []byte{0xB0, 0x05}
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)
		defer delete(instructions)

		incr := sim.decode_mov("10110000", data, 0, &instructions)
		testing.expect(t, incr == 1)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		testing.expect(t, bi.opcode == "1011")
		testing.expect(t, bi.word_op == '0')
		testing.expect(t, bi.reg == "000")
		testing.expect(t, bi.data.(u8) == 5)

		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == "AL")
		testing.expect(t, ai.source == "5")
	}

	{
		data := []byte{0xB8, 0x34, 0x12}
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)
		defer delete(instructions)

		incr := sim.decode_mov("10111000", data, 0, &instructions)
		testing.expect(t, incr == 2)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		testing.expect(t, bi.word_op == '1')
		testing.expect(t, bi.reg == "000")
		testing.expect(t, bi.data.(u16) == 0x1234)

		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == "AX")
		testing.expect(t, ai.source == "4660")
	}
}

@(test)
test_decode_mov_immediate_to_regmem_direct_address_word :: proc(t: ^testing.T) {
	log.info("test_decode_mov_immediate_to_regmem_direct_address_word...")

	data := []byte{0xC7, 0x06, 0x34, 0x12, 0x78, 0x56}
	instructions := make([dynamic]sim.ByteInstructions, 0, 1)
	defer delete(instructions)

	incr := sim.decode_mov("11000111", data, 0, &instructions)
	testing.expect(t, incr == 5)
	testing.expect(t, len(instructions) == 1)

	bi := instructions[0]
	testing.expect(t, bi.opcode == "1100011")
	testing.expect(t, bi.mod == "00")
	testing.expect(t, bi.rm == "110")
	testing.expect(t, bi.displacement.(u16) == 0x1234)
	testing.expect(t, bi.data.(u16) == 0x5678)

	ai, err := sim.write_assembly_instructions(bi)
	testing.expect(t, err == nil)
	testing.expect(t, ai.destination == "word [4660]")
	testing.expect(t, ai.source == "22136")
}

@(test)
test_decode_mov_accumulator_memory_variants :: proc(t: ^testing.T) {
	log.info("test_decode_mov_accumulator_memory_variants...")

	{
		data := []byte{0xA0, 0x34}
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)
		defer delete(instructions)

		incr := sim.decode_mov("10100000", data, 0, &instructions)
		testing.expect(t, incr == 1)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == "AL")
		testing.expect(t, ai.source == "[52]")
	}

	{
		data := []byte{0xA1, 0x34, 0x12}
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)
		defer delete(instructions)

		incr := sim.decode_mov("10100001", data, 0, &instructions)
		testing.expect(t, incr == 2)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == "AX")
		testing.expect(t, ai.source == "[4660]")
	}

	{
		data := []byte{0xA2, 0x34}
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)
		defer delete(instructions)

		incr := sim.decode_mov("10100010", data, 0, &instructions)
		testing.expect(t, incr == 1)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == "[52]")
		testing.expect(t, ai.source == "AL")
	}

	{
		data := []byte{0xA3, 0x34, 0x12}
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)
		defer delete(instructions)

		incr := sim.decode_mov("10100011", data, 0, &instructions)
		testing.expect(t, incr == 2)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == "[4660]")
		testing.expect(t, ai.source == "AX")
	}
}
