import unittest
import sys
from tools.tbgen import TestbenchGenerator

class TbgenTest(unittest.TestCase):
    def setUp(self):
        self.tbgen = TestbenchGenerator()

    def test_parser_header_method_handle_input_type(self):
        test_string   ="    input  wire [`GPIO_ADDR_BUS] addr,    // Address"
        expect_string ="    reg    [`GPIO_ADDR_BUS] addr;    // Address"

        result = self.tbgen.parser_header(test_string)
        self.assertEqual(result, expect_string)

    def test_parser_header_method_handle_output_type(self):
        test_string   ="    output reg  [`WORD_DATA_BUS] rd_data, // Read data"
        expect_string ="    wire   [`WORD_DATA_BUS] rd_data; // Read data"

        result = self.tbgen.parser_header(test_string)
        self.assertEqual(result, expect_string)

    def test_parser_header_method_handle_inout_type(self):
        test_string   ="    inout wire [`GPIO_IO_CH-1:0]  gpio_io  // Input/Output Port"
        expect_string ="    wire  [`GPIO_IO_CH-1:0]  gpio_io  // Input/Output Port"

        result = self.tbgen.parser_header(test_string)
        self.assertEqual(result, expect_string)

    def test_parser_header_method_handle_module_name(self):
        test_string   ="module gpio (   inout wire [`GPIO_IO_CH-1:0]  gpio_io );"
        expect_string ="module gpio_test;    wire  [`GPIO_IO_CH-1:0]  gpio_io ;"

        result = self.tbgen.parser_header(test_string)
        self.assertEqual(result, expect_string)

if __name__ == '__main__':

    unittest.main()

