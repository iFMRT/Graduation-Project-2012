#! /usr/bin/python3
import yaml
import argparse
from templite import Templite

def convert_to_case_result(case):

    case_result = [module_name+'_tb(']
    display_string = ''

    if 'display' in case:
        display_string = '$display("%s");' % (case.pop('display'))

    for port in task_ports:
        case_line = ('{:<36} {}').format('    '+case[port]+', ', '// '+port)
        case_result.append(case_line)

    # remove last ','
    # e.g task foobar(a, b, c,) to task foobar(a, b, c)
    case_result[-1] = case_result[-1].replace(',', ' ')

    case_result.append(');')
    case_result.insert(0, display_string)
    return case_result


def gen_testcase(yaml_src):

    testcase_list = list(yaml.load_all(yaml_src))
    testcase      = []

    for result in testcase_list:
        result = convert_to_case_result(result)
        testcase.append(result)

    testcase_ctx   = {'testcase'  : testcase,}

    # testcase context
    return testcase_ctx

if __name__ == "__main__":

    argparser = argparse.ArgumentParser(description='Testcase Generator')

    argparser.add_argument('src', nargs=1, action ='store', help ='Source file')
    argparser.add_argument('-t', nargs=1, action ='store', dest = 'template_file', help ='Template file')
    argparser.add_argument('-o', nargs=1, action ='store', dest ='obj_file', help   ='Object file')
    argparser.add_argument('-v', action ='version', version ='Testcase Generator Version: 0.1')

    args = argparser.parse_args()

    module_name = args.src[0].split('.')[0]

    with open(args.src[0], 'r') as yaml_file:
        task_ports = []
        lines = yaml_file.readlines()
        for line in lines:
            if '---' in line:
                break
            elif (':' not in line) or ('display' in line):
                # the line is comments
                # 'display' is not port, so it should not be appended
                continue
            else:
                task_ports.append(line.split(':')[0])

    with open(args.src[0], 'r') as yaml_file:
        testcase_ctx = gen_testcase(yaml_file)

    with open(args.template_file[0], 'r') as template:
            result = Templite(template.read()).render(testcase_ctx)

    if args.obj_file is not None:
        with open(args.obj_file[0], 'w') as f:
            f.write(result)