import unittest
import sys
from .tbgen import TestbenchGenerator

class TbgenTest(unittest.TestCase):
    def setUp(self):
        self.tbgen = TestbenchGenerator()

    # Test parse_header_method
    def test_parse_header_method_handle_input_type(self):
        test_string   = "    input  wire [`GPIO_ADDR_BUS] addr,    // Address"
        expect_string = "    reg    [`GPIO_ADDR_BUS] addr;    // Address"

        result = self.tbgen.parse_header(test_string)
        self.assertEqual(result, expect_string)

    def test_parse_header_method_handle_output_type(self):
        test_string   = "    output reg  [`WORD_DATA_BUS] rd_data, // Read data"
        expect_string = "    wire   [`WORD_DATA_BUS] rd_data; // Read data"

        result = self.tbgen.parse_header(test_string)
        self.assertEqual(result, expect_string)

    def test_parse_header_method_handle_inout_type(self):
        test_string   = "    inout wire [`GPIO_IO_CH-1:0]  gpio_io  // Input/Output Port"
        expect_string = "    wire  [`GPIO_IO_CH-1:0]  gpio_io  // Input/Output Port"

        result = self.tbgen.parse_header(test_string)
        self.assertEqual(result, expect_string)

    def test_parse_header_method_handle_module_name(self):
        test_string   = "module gpio (   inout wire [`GPIO_IO_CH-1:0]  gpio_io );"
        expect_string = "module gpio_test;    wire  [`GPIO_IO_CH-1:0]  gpio_io ;"

        result = self.tbgen.parse_header(test_string)
        self.assertEqual(result, expect_string)

    # Test parse_ports_method
    def test_parse_ports_method_return_correct_result(self):
        test_string = "module gpio ( output reg  [`WORD_DATA_BUS] rd_data, inout wire [`GPIO_IO_CH-1:0]  gpio_io ); // comments"

        self.tbgen.parse_ports(test_string)
        self.assertEqual(self.tbgen.ports_name, ['rd_data', 'gpio_io'])
        self.assertEqual(self.tbgen.ports_width['rd_data'], '[`WORD_DATA_BUS]')
        self.assertEqual(self.tbgen.ports_width['gpio_io'], '[`GPIO_IO_CH-1:0]')
        self.assertEqual(self.tbgen.ports_type['rd_data'], 'output')
        self.assertEqual(self.tbgen.ports_type['gpio_io'], 'inout')

    def test_gen_dut_method_return_correct_result(self):
        self.tbgen.src_file_content = ["module gpio ( output reg  [`WORD_DATA_BUS] rd_data, inout wire [`GPIO_IO_CH-1:0]  gpio_io ); // comments"]
        self.tbgen.parser()

        result        = self.tbgen.gen_dut()
        expect_string = "    gpio gpio (\n        .rd_data(rd_data),\n        .gpio_io(gpio_io)\n    );"

        self.assertEqual(result, expect_string)
