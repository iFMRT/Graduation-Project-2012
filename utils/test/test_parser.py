import unittest
from tools.parser import Parser


class ParserTest(unittest.TestCase):
    def test_parser_divide_method_returns_correct_result(self):
        instruction = "ADDI r1, r0, 4"
        parser = Parser()
        result = parser.divide(instruction)
        self.assertEqual(['addi', 'r1', 'r0', '4'], result)
