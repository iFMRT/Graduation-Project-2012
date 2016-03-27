import sys
import yaml
sys.path.append("..")
import re
from template.template import Template

class TestbenchGenerator(object):
    def __init__(self):
        self.module_header = ''
        self.ports_name = []
        self.ports_width = {}
        self.ports_type = {}

    def open_file(self, src_file_name=None):
        try:
            with open(src_file_name, 'r') as src_file:
                self.src_file_content = src_file.readlines()
        except Exception as e:
            print("ERROR: Open and read file error.\n ERROR:    %s" % e)
            sys.exit(1)


    def render(self):
        context = {'header': self.module_header, 'dut': self.gen_dut()}
        with open('template.v') as template_flie:
            self.result = Template(template_flie.read()).render(**context)

    def parse_header(self, line):
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

    def parse_ports(self, line):
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


    def parser(self):
        for line in self.src_file_content:
            if 'input' in line or 'output' in line or 'inout' in line:
                self.parse_ports(line)

            # break when read to module header end
            if ');' in line:
                self.module_header += self.parse_header(line)
                break

            self.module_header += self.parse_header(line)

    def gen_dut(self):
        dut = "    " + self.module_name + " " + self.module_name + " (\n"
        last_port = self.ports_name.pop()

        for name in self.ports_name:
            dut += "        " + "." + name + "(" + name + "),\n"

        dut += "        " + "." + last_port + "(" + last_port + ")\n"
        dut += "    );"

        return dut

    def gen_dut_task(self):
        width_ports = []
        ports       = []
        with open('template/task.v', 'r') as f:
            task_template = f.read()

        for idx, port in enumerate(self.ports_name):
            if self.ports_type[port] != 'input':
                ports.append(port)
                width_ports.append(self.ports_width[port] + ' _' + port )


        last_port = ports.pop()
        context   = {'task_name':   'gpio_tb',
                     'width_ports': width_ports,
                     'ports':       ports,
                     'last_port':   last_port,
        }

        task = Template(task_template).render(**context)

        return task

    def gen_test_case_yaml(self):
        init_input  = {}
        init_output = {'display': 'something you want to display'}
        
        for port in self.ports_name:
            if self.ports_type[port] == 'input':
                init_input[port]  = "placeholder"
            else:
                init_output[port] = "placeholder"

        return yaml.dump({
            'init input': init_input,
            'init output': init_output,
        }, indent=4, default_flow_style=False)

    def load_yaml(self, testcase):
        return yaml.load(testcase)

    def write_file(self):
        # Create Testbench File
        with open('gpio_test.v', 'w') as f:
            f.write(self.result)


if __name__ == "__main__":

    tbg = TestbenchGenerator()
    tbg.open_file('gpio.v')
    tbg.parser()
    tbg.render()
    tbg.write_file()


