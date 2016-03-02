import unittest
from .template import Compiler
from .template import TestFragment, TestEach, TestText, TestVariable
from .template import VAR_FRAGMENT, OPEN_BLOCK_FRAGMENT, CLOSE_BLOCK_FRAGMENT, TEXT_FRAGMENT

class FragmentTest(unittest.TestCase):
    def test_fragment_object_has_correct_property(self):
        open_obj  = TestFragment("{% each [1, 2, 3] %}")
        text_obj  = TestFragment("<div>")
        var_obj   = TestFragment("{{ var }}")
        close_obj = TestFragment("{% end %}")

        self.assertEqual(open_obj.text, "each [1, 2, 3]")
        self.assertEqual(open_obj.type, OPEN_BLOCK_FRAGMENT)
        self.assertEqual(text_obj.text, "<div>")
        self.assertEqual(text_obj.type, TEXT_FRAGMENT)
        self.assertEqual(var_obj.text, "var")
        self.assertEqual(var_obj.type, VAR_FRAGMENT)
        self.assertEqual(close_obj.text, "end")
        self.assertEqual(close_obj.type, CLOSE_BLOCK_FRAGMENT)

class CompilerTest(unittest.TestCase):
    def setUp(self):
        self.compiler = Compiler("{%each [1, 2, 3]%} <div> {{var}} </div> {%end%}")
        self.each_fragment = self.compiler.each_fragment()

    def test_each_fragment_method_generate_fragment_objects(self):
        for item in self.each_fragment:
            self.assertIsInstance(item, TestFragment)

    def test_create_node_method_return_correct_result(self):
        node_objs = []
        for item in self.each_fragment:
            node_objs.append(self.compiler.create_node(item))

        # self.assertIsInstance(node_objs[0], TestEach)
        # self.assertIsInstance(node_objs[1], TestText)
        # self.assertIsInstance(node_objs[2], TestVariable)
        # self.assertIsInstance(node_objs[3], TestText)
