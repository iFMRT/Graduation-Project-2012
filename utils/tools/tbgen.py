import sys
import re

class TestbenchGenerator(object):

    def open_file(self, src_file_name=None):

        try:
            with open(src_file_name, 'r') as src_file:
                self.src_file_content = src_file.readlines()

        except Exception as e:
            print("ERROR: Open and read file error.\n ERROR:    %s" % e)
            sys.exit(1)

    def parser_header(self, line):
        # remove 'wire' and 'reg'
        # remove ')' is the same as replacing ');' to ';'
        line = re.sub('\wire|reg|\(|\)', '', line)

        # replace input to reg, output and inout to wire
        line = re.sub('input', 'reg ', line)
        line = re.sub('output', 'wire', line)
        line = re.sub('inout', 'wire', line)

        # replace ',' to ';'
        line = re.sub(',', ';', line)

        # change module_name to module_name_test
        if 'module' in line:
            self.module_name = line.split()[1]
            line = re.sub(self.module_name, self.module_name+'_test;', line, 1)

        return line

    def parser_args(self, line):
        args = []

        remove_items = ['input', 'output', 'inout',
                        'reg', 'wire',
                        ');', ',', ')', '',
        ]

        # remove '(' or 'module dut_name ('
        if '(' in line:
            line = line.split('(')[1]

        # remove "//" line comments
        if '//' in line:
            line = line.split('//')[0]

        line = line.split()

        for item in line:
            if item not in remove_items and '[' not in item:
                # remove ',' from 'arg,'
                item = re.sub(',', '', item)
                # remove ')' from 'arg)'
                item = re.sub('\\)', '', item)
                # remove ');' from 'arg);'
                item = re.sub('\\);', '', item)
                args.append(item)

        return args

    def parser(self):
        self.module_header = ''
        self.args_list = []

        for line in self.src_file_content:
            if 'input' in line or 'output' in line or 'inout' in line:
                self.args_list += self.parser_args(line)

            # break when read to module header end
            if ');' in line:
                self.module_header += self.parser_header(line)
                break

            self.module_header += self.parser_header(line)

    def gen_dut(self):
        dut = ""

        dut = "    " + self.module_name + " " + self.module_name + " (\n"

        last_arg = self.args_list.pop()

        for arg in self.args_list:
            dut += "        " + "." + arg + "(" + arg + "),\n"

        dut += "        " + "." + last_arg + "(" + last_arg + ")\n"

        dut += "    );"

        return dut

    def write_file(self):
        # Create Testbench File
        with open('gpio_test.v', 'w') as f:
            f.write(self.module_header)

if __name__ == "__main__":

    tbg = TestbenchGenerator()
    tbg.open_file('gpio.v')
    tbg.parser()
    tbg.write_file()


