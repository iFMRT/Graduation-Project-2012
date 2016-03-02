import unittest
from .template import Compiler

class CompilerTest(unittest.TestCase):
    def setUp(self):
        self.compiler = Compiler("{%each [1, 2, 3]%} <div> {{var}} </div> {%end%}")
    def test_each_fragment_method_split_fragments(self):
        result_list = []
        for item in self.compiler.each_fragment():
            result_list.append(item)

        self.assertEquals(result_list, ["{%each [1, 2, 3]%}", " <div> ", "{{var}}", " </div> ", "{%end%}"])
