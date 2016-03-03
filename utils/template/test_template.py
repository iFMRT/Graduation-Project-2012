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
            if item.type == CLOSE_BLOCK_FRAGMENT:
                continue
            node_objs.append(self.compiler.create_node(item))

        self.assertIsInstance(node_objs[0], TestEach)
        self.assertIsInstance(node_objs[1], TestText)
        self.assertIsInstance(node_objs[2], TestVariable)
        self.assertIsInstance(node_objs[3], TestText)

    def test_complie_method_create_children_for_each_node(self):
        root_children      = self.compiler.compile().children
        root_grandchildren = root_children[0].children

        self.assertEqual(len(root_children), 1)
        self.assertIsInstance(root_children[0], TestEach)
        self.assertEqual(len(root_grandchildren), 3)
        self.assertIsInstance(root_grandchildren[0], TestText)
        self.assertIsInstance(root_grandchildren[1], TestVariable)
        self.assertIsInstance(root_grandchildren[2], TestText)

    def test_complie_method_create_nested_children_for_each_node(self):
        self.compiler = Compiler(
            "{%each [1, 2, 3]%} <div> {{var}} </div> {%end%}" +
            "{{var}}" +
            "{%each [1, 2, 3]%} <div> {{var}} </div> {%end%}"
        )

        root_children             = self.compiler.compile().children
        root_grandchildren_left   = root_children[0].children
        root_grandchildren_center = root_children[1].children
        root_grandchildren_right  = root_children[2].children

        # Test all children of root
        self.assertEqual(len(root_children), 3)
        self.assertIsInstance(root_children[0], TestEach)
        self.assertIsInstance(root_children[1], TestVariable)
        self.assertIsInstance(root_children[2], TestEach)

        # Test left child of root
        self.assertEqual(len(root_grandchildren_left), 3)
        self.assertIsInstance(root_grandchildren_left[0], TestText)
        self.assertIsInstance(root_grandchildren_left[1], TestVariable)
        self.assertIsInstance(root_grandchildren_left[2], TestText)

        # Test center child of root
        self.assertEqual(len(root_grandchildren_center), 0)

        # Test right child of root
        self.assertEqual(len(root_grandchildren_right), 3)
        self.assertIsInstance(root_grandchildren_right[0], TestText)
        self.assertIsInstance(root_grandchildren_right[1], TestVariable)
        self.assertIsInstance(root_grandchildren_right[2], TestText)

