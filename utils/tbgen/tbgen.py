import sys
import yaml
import argparse
import re
from templite import Templite

class TestbenchGenerator(object):
    def __init__(self):
        self.module_name = ''
        self.ports_name  = []
        self.ports_width = {}
        self.ports_type  = {}

    # Parse each line of module header,
    # and assign module name to self.module_name.
    def __parse_header_line(self, line):
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


    def __parse_ports(self, line):
        port_type    = []
        port_width   = []
        port_name    = []
        type_list    = ['input', 'output', 'inout']
        remove_items = ['reg', 'wire',
                        ');', ',', ')', '',
        ]

        # remove '(' or 'module dut_name ('
        if '(' in line:
            line = line.split('(')[1]
        # remove "//" line comments
        if '//' in line:
            port_comment = line.split('//')[1]
            line = line.split('//')[0]
        line = line.split()

        for item in line:
            if item in type_list:
                port_type.append(item)
            elif '[' in item:
                port_width.append(item)
            elif item not in remove_items:
                # remove ',' from 'arg,'
                item = re.sub(',', '', item)
                # remove ')' from 'arg)'
                item = re.sub('\\)', '', item)
                # remove ');' from 'arg);'
                item = re.sub('\\);', '', item)
                # if one port has no width, use '' instead
                if len(port_width) - len(port_name) != 1:
                    port_width.append('')
                port_name.append(item)

        # idx is for index
        for idx, name in enumerate(port_name):
            self.ports_name.append(name)
            self.ports_width[name] = port_width[idx]
            self.ports_type[name]  = port_type[idx]


    def parser_header(self, module_src):
        module_header = ''
        for line in module_src:
            if 'input' in line or 'output' in line or 'inout' in line:
                self.__parse_ports(line)

            # break when read to module header end
            if ');' in line:
                module_header += self.__parse_header_line(line)
                break

            module_header += self.__parse_header_line(line)

        module_header += '\n'
        return module_header


    def gen_footer(self):
        module_footer = """\n\t/******** Output Waveform ********/
    initial begin
       $dumpfile("gpio.vcd");
       $dumpvars(0, gpio);
    end

endmodule"""

        return module_footer
    def gen_dut(self):
        dut = self.module_name + " " + self.module_name + " (\n"
        last_port = self.ports_name.pop()

        for name in self.ports_name:
            dut += "        " + "." + name + "(" + name + "),\n"

        dut += "        " + "." + last_port + "(" + last_port + ")\n"
        dut += "    );"

        return dut


    def gen_dut_task(self):

        width_ports = []
        ports       = []

        for idx, port in enumerate(self.ports_name):
            if self.ports_type[port] != 'input':
                ports.append(port)
                width_ports.append(self.ports_width[port] + ' _' + port )

        last_port = ports.pop()

        task_ctx   = {'task_name'  : 'gpio_tb',
                     'width_ports': width_ports,
                     'ports'      : ports,
                     'last_port'  : last_port,
        }

        # task context
        return task_ctx


    def gen_test_case_yaml(self):
        init_input  = {}
        init_output = {'display': 'something you want to display'}

        for port in self.ports_name:
            if self.ports_type[port] == 'input':
                init_input[port]  = "placeholder"
            else:
                init_output[port] = "placeholder"

        return yaml.dump_all([init_input, init_output,],
                             indent=4,
                             default_flow_style=False
        )


    def __convert_to_case_input(self, case):

        case_input = []

        for(k, v) in case.items():
            case_input.append(k+' <= '+v+';')

        return case_input

    def __convert_to_case_result(self, case):

        case_result = ['gpio_tb(']
        display_string = ''

        if 'display' in case:
            display_string = '$display("%s");' % (case.pop('display'))

        for(k, v) in case.items():
            case_result.append('\t'+v+', '+'// '+k)

        case_result.append(');')
        return case_result


    def gen_testcase(self, yaml_src):

        testcase_list = list(yaml.load_all(yaml_src))
        testcase      = []

        first_case = self.__convert_to_case_input(testcase_list.pop(0))
        last_case  = self.__convert_to_case_result(testcase_list.pop())

        testcase_list = list(zip(testcase_list, testcase_list[1:]))[::2]

        for (result, input) in testcase_list:
            case_pair = []
            result = self.__convert_to_case_result(result)
            input  = self.__convert_to_case_input(input)

            case_pair.append(result)
            case_pair.append(input)

            testcase.append(case_pair)

        testcase_ctx   = {'testcase'  : testcase,
                          'first_case': first_case,
                          'last_case' : last_case,
        }

        # testcase context
        return testcase_ctx


if __name__ == "__main__":

    argparser = argparse.ArgumentParser(description='Testbench Generator')
    exclusive_group = argparser.add_mutually_exclusive_group()

    argparser.add_argument('src', nargs=1, action ='store', help ='Source file')
    exclusive_group.add_argument('-g', nargs=1, action ='store', dest = 'yaml_obj', help ='Generate a yaml template file')
    exclusive_group.add_argument('-y', nargs=1, action ='store', dest = 'yaml_src', help ='Specify a yaml template file')
    argparser.add_argument('-t', nargs=1, action ='store', dest = 'template_file', help ='Template file')
    argparser.add_argument('-o', nargs=1, action ='store', dest ='obj_file', help   ='Object file')
    argparser.add_argument('-v', action ='version', version ='Testbench Generator Version: 0.1')

    args = argparser.parse_args()

    tbg = TestbenchGenerator()

    with open(args.src[0], 'r') as src_file:
        module_header = tbg.parser_header(src_file.readlines())
        module_footer = tbg.gen_footer()
        dut           = tbg.gen_dut()
        task_ctx      = tbg.gen_dut_task()

    result = ''
    if args.yaml_obj:
        with open(args.yaml_obj[0], 'w') as f:
            f.write(tbg.gen_test_case_yaml())
        sys.exit(0)
    elif args.template_file:
        if not args.yaml_src:
            print("You must specify a yaml file!")
            sys.exit(1)

        with open(args.yaml_src[0], 'r') as yaml_file:
            testcase_ctx = tbg.gen_testcase(yaml_file)

        task_ctx.update(testcase_ctx)
        ctx = task_ctx.copy()
        ctx['header'] = module_header
        ctx['dut']    = dut
        ctx['footer'] = module_footer

        with open(args.template_file[0], 'r') as template:
            result = Templite(template.read()).render(ctx)
    else:
        result = module_header + dut + module_footer

    if args.obj_file is not None:
        with open(args.obj_file[0], 'w') as f:
            f.write(result)