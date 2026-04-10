package tests

import "core:testing"
import "core:log"
import "../sim"

@(test)
test_general_bit_string_to_opt :: proc(t: ^testing.T) {
	log.info("test_general_bit_string_to_opt...")

	test_cases := []struct {
		input:    string,
		expected: sim.Opcode_Variant,
	}{
		{"00000100", .IMMEDIATE_TO_ACCUMULATOR},
		{"00101101", .IMMEDIATE_TO_ACCUMULATOR},
		{"00111100", .IMMEDIATE_TO_ACCUMULATOR},
		{"10000011", .IMMEDIATE_TO_REGMEM},
		{"00000001", .REGMEM_WITH_REG},
		{"00101001", .REGMEM_WITH_REG},
		{"00111001", .REGMEM_WITH_REG},
		{"11111111", .UNDEFINED},
	}

	for tc in test_cases {
		result := sim._general_bit_string_to_opt(tc.input)
		testing.expectf(t, result == tc.expected,
			"_general_bit_string_to_opt(%s): got %v expected %v", tc.input, result, tc.expected)
	}
}

@(test)
test_decode_general_regmem_with_reg_for_add_sub_cmp :: proc(t: ^testing.T) {
	log.info("test_decode_general_regmem_with_reg_for_add_sub_cmp...")

	test_cases := []struct {
		s1:   string,
		data: []byte,
		code: sim.Transfer_Code,
	}{
		{"00000001", []byte{0x01, 0xC1}, sim.Data_Transfer_Code.ADD},
		{"00101001", []byte{0x29, 0xC1}, sim.Data_Transfer_Code.SUB},
		{"00111001", []byte{0x39, 0xC1}, sim.Data_Transfer_Code.CMP},
	}

	for tc in test_cases {
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)

		incr := sim.decode_instructions(tc.s1, tc.data, 0, tc.code, &instructions)
		testing.expect(t, incr == 1)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		testing.expect(t, bi.code == tc.code)
		testing.expect(t, bi.mod == "11")
		testing.expect(t, bi.reg == "000")
		testing.expect(t, bi.rm == "001")

		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.code == tc.code)
		testing.expect(t, ai.destination == "CX")
		testing.expect(t, ai.source == "AX")

		delete(instructions)
	}
}

@(test)
test_decode_general_immediate_to_accumulator :: proc(t: ^testing.T) {
	log.info("test_decode_general_immediate_to_accumulator...")

	test_cases := []struct {
		s1:                   string,
		data:                 []byte,
		code:                 sim.Transfer_Code,
		expected_incr:        int,
		expected_destination: string,
		expected_source:      string,
	}{
		{"00000100", []byte{0x04, 0x05}, sim.Data_Transfer_Code.ADD, 1, "AL", "5"},
		{"00000101", []byte{0x05, 0x34, 0x12}, sim.Data_Transfer_Code.ADD, 2, "AX", "4660"},
		{"00101100", []byte{0x2C, 0x06}, sim.Data_Transfer_Code.SUB, 1, "AL", "6"},
		{"00101101", []byte{0x2D, 0x78, 0x56}, sim.Data_Transfer_Code.SUB, 2, "AX", "22136"},
		{"00111100", []byte{0x3C, 0x09}, sim.Data_Transfer_Code.CMP, 1, "AL", "9"},
		{"00111101", []byte{0x3D, 0x34, 0x12}, sim.Data_Transfer_Code.CMP, 2, "AX", "4660"},
	}

	for tc in test_cases {
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)

		incr := sim.decode_instructions(tc.s1, tc.data, 0, tc.code, &instructions)
		testing.expectf(t, incr == tc.expected_incr,
			"decode_instructions incr: got %d expected %d", incr, tc.expected_incr)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		testing.expect(t, bi.code == tc.code)
		testing.expect(t, bi.reg == "000")

		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.code == tc.code)
		testing.expect(t, ai.destination == tc.expected_destination)
		testing.expect(t, ai.source == tc.expected_source)

		delete(instructions)
	}
}

@(test)
test_decode_general_immediate_to_regmem_reg_mode_sign_paths :: proc(t: ^testing.T) {
	log.info("test_decode_general_immediate_to_regmem_reg_mode_sign_paths...")

	test_cases := []struct {
		s1:              string,
		data:            []byte,
		code:            sim.Transfer_Code,
		expected_incr:   int,
		expected_source: string,
	}{
		{"10000011", []byte{0x83, 0xC1, 0x05}, sim.Data_Transfer_Code.ADD, 2, "5"},
		{"10000001", []byte{0x81, 0xC1, 0x34, 0x12}, sim.Data_Transfer_Code.CMP, 3, "4660"},
	}

	for tc in test_cases {
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)

		incr := sim.decode_instructions(tc.s1, tc.data, 0, tc.code, &instructions)
		testing.expect(t, incr == tc.expected_incr)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		testing.expect(t, bi.code == tc.code)
		testing.expect(t, bi.mod == "11")
		testing.expect(t, bi.rm == "001")

		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == "CX")
		testing.expect(t, ai.source == tc.expected_source)

		delete(instructions)
	}
}

@(test)
test_decode_general_immediate_to_regmem_memory_modes :: proc(t: ^testing.T) {
	log.info("test_decode_general_immediate_to_regmem_memory_modes...")

	test_cases := []struct {
		s1:                   string,
		data:                 []byte,
		code:                 sim.Transfer_Code,
		expected_incr:        int,
		expected_destination: string,
		expected_source:      string,
	}{
		{"10000000", []byte{0x80, 0x00, 0x7F}, sim.Data_Transfer_Code.ADD, 2, "byte [BX + SI]", "127"},
		{"10000011", []byte{0x83, 0x06, 0x34, 0x12, 0x05}, sim.Data_Transfer_Code.SUB, 4, "word [4660]", "5"},
		{"10000001", []byte{0x81, 0x06, 0x34, 0x12, 0x78, 0x56}, sim.Data_Transfer_Code.CMP, 5, "word [4660]", "22136"},
		{"10000011", []byte{0x83, 0x40, 0x07, 0x05}, sim.Data_Transfer_Code.ADD, 3, "word [BX + SI + 7]", "5"},
		{"10000001", []byte{0x81, 0x40, 0x07, 0x78, 0x56}, sim.Data_Transfer_Code.SUB, 4, "word [BX + SI + 7]", "22136"},
		{"10000011", []byte{0x83, 0x80, 0x34, 0x12, 0x05}, sim.Data_Transfer_Code.CMP, 4, "word [BX + SI + 4660]", "5"},
		{"10000001", []byte{0x81, 0x80, 0x34, 0x12, 0x78, 0x56}, sim.Data_Transfer_Code.ADD, 5, "word [BX + SI + 4660]", "22136"},
	}

	for tc in test_cases {
		instructions := make([dynamic]sim.ByteInstructions, 0, 1)

		incr := sim.decode_instructions(tc.s1, tc.data, 0, tc.code, &instructions)
		testing.expectf(t, incr == tc.expected_incr,
			"decode_instructions incr: got %d expected %d", incr, tc.expected_incr)
		testing.expect(t, len(instructions) == 1)

		bi := instructions[0]
		testing.expect(t, bi.code == tc.code)

		ai, err := sim.write_assembly_instructions(bi)
		testing.expect(t, err == nil)
		testing.expect(t, ai.destination == tc.expected_destination)
		testing.expect(t, ai.source == tc.expected_source)

		delete(instructions)
	}
}
