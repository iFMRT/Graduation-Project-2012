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
            line = re.sub(line.split()[1], line.split()[1]+'_test;', line, 1)

        return line

    def gen_module_header(self):
        module_header = ''

        for line in self.src_file_content:

            # break when read to module header end
            if ');' in line:
                module_header += self.parser_header(line)
                break

            module_header += self.parser_header(line)

        return module_header

    def write_file(self):
        # Create Testbench File
        with open('gpio_test.v', 'w') as f:
            f.write(self.gen_module_header())

if __name__ == "__main__":

    tbg = TestbenchGenerator()
    tbg.open_file('gpio.v')
    tbg.write_file()


