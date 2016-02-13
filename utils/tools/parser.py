import re


class Parser(object):
    def divide(self, instruction):
        instruction = instruction.lower()
        return re.split(r'\s*[,\s]\s*', instruction)
