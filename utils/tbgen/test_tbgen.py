# -*- coding: utf-8 -*-

import unittest
from .tbgen import TestbenchGenerator

class TbGenTest(unittest.TestCase):
    def setUp(self):
        self.tbgen = TestbenchGenerator()

    # Test parse_header_method
    def test_parse_header_method_handle_input_type(self):
        test_string   = "    input  wire [`GPIO_ADDR_BUS] addr,    // Address"
        expect_string = "    reg    [`GPIO_ADDR_BUS] addr;    // Address"

        result = self.tbgen._TestbenchGenerator__parse_header_line(test_string)
        self.assertEqual(result, expect_string)

    def test_parse_header_method_handle_output_type(self):
        test_string   = "    output reg  [`WORD_DATA_BUS] rd_data, // Read data"
        expect_string = "    wire   [`WORD_DATA_BUS] rd_data; // Read data"

        result = self.tbgen._TestbenchGenerator__parse_header_line(test_string)
        self.assertEqual(result, expect_string)

    def test_parse_header_method_handle_inout_type(self):
        test_string   = "    inout wire [`GPIO_IO_CH-1:0]  gpio_io  // Input/Output Port"
        expect_string = "    wire  [`GPIO_IO_CH-1:0]  gpio_io  // Input/Output Port"

        result = self.tbgen._TestbenchGenerator__parse_header_line(test_string)
        self.assertEqual(result, expect_string)

    def test_parse_header_method_handle_module_name(self):
        test_string   = "module gpio (   inout wire [`GPIO_IO_CH-1:0]  gpio_io );"
        expect_string = "module gpio_test;    wire  [`GPIO_IO_CH-1:0]  gpio_io ;"

        result = self.tbgen._TestbenchGenerator__parse_header_line(test_string)
        self.assertEqual(result, expect_string)
        self.assertEqual(self.tbgen.module_name, "gpio")

    # Test parse_ports_method
    def test_parse_ports_method_return_correct_result(self):
        test_string = "module gpio ( output reg  [`WORD_DATA_BUS] rd_data, input rd_read, inout wire [`GPIO_IO_CH-1:0]  gpio_io ); // comments"

        self.tbgen._TestbenchGenerator__parse_ports(test_string)

        self.assertEqual(self.tbgen.ports_name, ['rd_data', 'rd_read', 'gpio_io'])
        self.assertEqual(self.tbgen.ports_width['rd_data'], '[`WORD_DATA_BUS]')
        self.assertEqual(self.tbgen.ports_width['rd_read'], '')
        self.assertEqual(self.tbgen.ports_width['gpio_io'], '[`GPIO_IO_CH-1:0]')
        self.assertEqual(self.tbgen.ports_type['rd_data'], 'output')
        self.assertEqual(self.tbgen.ports_type['gpio_io'], 'inout')

    def test_gen_dut_method_return_correct_result(self):
        module_src = ["module gpio ( output reg  [`WORD_DATA_BUS] rd_data, inout wire [`GPIO_IO_CH-1:0]  gpio_io ); // comments"]
        self.tbgen.parser_header(module_src)

        result        = self.tbgen.gen_dut()
        expect_string = "    gpio gpio (\n        .rd_data(rd_data),\n        .gpio_io(gpio_io)\n    );"

        self.assertEqual(result, expect_string)

    # def test_gen_dut_task_method_return_correct_result(self):
#         self.tbgen.src_file_content = ["module gpio (input clk, input reset, output reg  [`WORD_DATA_BUS] rd_data, output rd_read, inout wire [`GPIO_IO_CH-1:0]  gpio_io ); // comments"]
#         self.tbgen.parser()

#         result        = self.tbgen.gen_dut_task()
#         expect_string = """    task gpio_tb;
#         input [`WORD_DATA_BUS] _rd_data;
#         input  _rd_read;
#         input [`GPIO_IO_CH-1:0] _gpio_io;

#         begin
#             if((rd_data  === _rd_data)  &&
#                (rd_read  === _rd_read)  &&
#                (gpio_io  === _gpio_io)
#               ) begin
#                 $display("Test Succeeded !");
#             end else begin
#                 $display("Test Failed !");
#             end
#         end
#     endtask
# """
#         self.assertEqual(result, expect_string)

#     def test_gen_test_case_yaml_method(self):
#         self.tbgen.src_file_content = ["module gpio ( input clk, input reset, output reg  [`WORD_DATA_BUS] rd_data, inout wire [`GPIO_IO_CH-1:0]  gpio_io ); // comments"]
#         self.tbgen.parser()

#         result = self.tbgen.gen_test_case_yaml()
#         expect_string = """init input:
#     clk: placeholder
#     reset: placeholder
# init output:
#     display: something you want to display
#     gpio_io: placeholder
#     rd_data: placeholder
# """
#         self.assertEqual(result, expect_string)

#     def test_parse_test_case_yaml_method_return_correct_result(self):
#         parsed_string = """init input:
#     clk: placeholder
#     reset: placeholder
# init output:
#     display: something you want to display
#     gpio_io: placeholder
#     rd_data: placeholder
# """
#         result = self.tbgen.load_yaml(parsed_string)
#         expect = {
#             'init input':{
#                 'clk': 'placeholder',
#                 'reset': 'placeholder'
#             },
#             'init output': {
#                 'display': 'something you want to display',
#                 'gpio_io': 'placeholder',
#                 'rd_data': 'placeholder'
#             }
#         }

#         self.assertEqual(result, expect)

#     def test_args_property_return_correct_result(self):
#         result = self.tbgen.args.parse_args(['-s', 'gpio.v',
#                                              '-o', 'gpio_test.v',
#                                              '-y', 'testcase.yaml',
#                                              '-t', 'template'
#         ])

#         self.assertEqual(result.src_file, 'gpio.v')
#         self.assertEqual(result.obj_file, 'gpio_test.v')
#         self.assertEqual(result.yaml_file, 'testcase.yaml')
#         self.assertEqual(result.template_dir, 'template')



if __name__ == '__main__':
    unittest.main()
