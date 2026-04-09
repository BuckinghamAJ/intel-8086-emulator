package tests

import "core:testing"
import "core:log"
import "../decoder"

@(test)
test_reg_assembly :: proc(t: ^testing.T) {
	log.info("test_reg_assembly...")

	// Test cases for reg_assembly
	test_cases := []struct {
		reg:     string,
		word_op: rune,
		expected: string
	}{
		{"000", '0', "AL"},
		{"000", '1', "AX"},
		{"001", '0', "CL"},
		{"001", '1', "CX"},
		{"010", '0', "DL"},
		{"010", '1', "DX"},
	}

	for tc, _ in test_cases {
		result := decoder.reg_assembly(tc.reg, tc.word_op)
		testing.expect(t, result == tc.expected)
	}

}

@(test)
test_rm_assembly :: proc(t: ^testing.T) {
	log.info("test_rm_assembly...")

	// Test cases for rm_assembly
	test_cases := []struct {
		rm:       string,
		word_op:  rune,
		mod:      decoder.Mod_Field_Code,
		expected: string
	}{
		{"000", '0', .REG_MODE, "AL"},
		{"000", '1', .REG_MODE, "AX"},
		{"001", '0', .REG_MODE, "CL"},
		{"001", '1', .REG_MODE, "CX"},
		{"010", '0', .REG_MODE, "DL"},
		{"010", '1', .REG_MODE, "DX"},
	}

	for tc, _ in test_cases {
		bi := decoder.ByteInstructions{
			byte2 = decoder.Byte2{ rm = tc.rm },
			byte1 = decoder.Byte1{ word_op = tc.word_op },
		}
		result, err := decoder.rm_assembly(bi, tc.mod)
		testing.expect(t, err == nil)
		testing.expect(t, result == tc.expected)
	}

}
