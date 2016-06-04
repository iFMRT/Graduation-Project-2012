import random
import re
import argparse


def int_to_verilog(int_num):
    result = re.findall('..', "{0:0{1}x}".format(int_num, 8))
    result.reverse()

    return result

random_num_list = []
for i in range(0, 100):
    random_num_list.append(" ".join(int_to_verilog(random.randint(0, 1023))))

random_num_list = [random_num_list[x:x + 4]
                   for x in range(0, len(random_num_list), 4)]

argparser = argparse.ArgumentParser(
    description='Random Verilog Data Generator')

argparser.add_argument('src', nargs=1, action='store', help='Source file')
argparser.add_argument('-a', nargs=1, action='store',
                       dest='addr', help='Address')

args = argparser.parse_args()

with open(args.src[0], 'a') as f:
    f.write("@" + str(hex(int(args.addr[0]))) + "\n")
    for item in random_num_list:
        f.write(" ".join(item) + '\n')
