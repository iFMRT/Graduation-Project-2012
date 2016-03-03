import re
import ast

# Fragment Type
VAR_FRAGMENT         = 0
OPEN_BLOCK_FRAGMENT  = 1
CLOSE_BLOCK_FRAGMENT = 2
TEXT_FRAGMENT        = 3

# Split variable token "{{..}}" and block token "{%...%}"
VAR_TOKEN_START   = '{{'
VAR_TOKEN_END     = '}}'
BLOCK_TOKEN_START = '{%'
BLOCK_TOKEN_END   = '%}'

TOK_REGEX = re.compile(r"(%s.*?%s|%s.*?%s)" % (
    VAR_TOKEN_START,
    VAR_TOKEN_END,
    BLOCK_TOKEN_START,
    BLOCK_TOKEN_END
))

WHITESPACE = re.compile('\s+')

def eval_expression(expr):
    # TODO: return iterator literal
    return 'literal', ast.literal_eval(expr)
    # TODO: return iterator variable name


def resolve(name, context):
    return context[name]


class _Fragment(object):
    def __init__(self, raw_text):
        self.raw = raw_text

    @property
    def text(self):
        # "{{ foo }}" --> "foo"
        # "{% each bar %}" --> "each bar"
        if self.raw[:2] in (VAR_TOKEN_START, BLOCK_TOKEN_START):
            return self.raw[2:-2].strip()
        return self.raw

    @property
    def type(self):
        raw_start = self.raw[:2]
        if raw_start == VAR_TOKEN_START:
            return VAR_FRAGMENT
        elif raw_start == BLOCK_TOKEN_START:
            return CLOSE_BLOCK_FRAGMENT if self.text[:3] == 'end' else OPEN_BLOCK_FRAGMENT
        else:
            return TEXT_FRAGMENT


# Just for test
TestFragment = _Fragment

class _Node(object):
    creates_scope = False

    def __init__(self, fragment=None):
        self.children = []
        self.process_fragment(fragment)

    def process_fragment(self, fragment):
        pass

    def render(self, context):
        pass

    def render_children(self, context):
        def render_child(child):
            child_html = child.render(context)
            return '' if not child_html else str(child_html)
        return ''.join(list(map(render_child, self.children)))

class _ScopableNode(_Node):
    creates_scope = True

class _Root(_Node):
   def render(self, context):
       return self.render_children(context)


class _Variable(_Node):
    def process_fragment(self, fragment):
        self.name = fragment

    def render(self, context):
        return resolve(self.name, context)

# Just for test
TestVariable = _Variable

class _Each(_ScopableNode):
    def process_fragment(self, fragment):
        # "each iterator" to "iterator", it is for iterator
        it = WHITESPACE.split(fragment, 1)[1]
        # change to python iterator
        self.it = eval_expression(it)
        # TODO: check TemplateSyntaxError

    def render(self, context):
        # TODO: process iterator variable name
        items = self.it[1]
        def render_item(item):
            return  self.render_children({'it': item})
        return ''.join(list(map(render_item, items)))

# Just for test
TestEach = _Each


class _Text(_Node):
    def process_fragment(self, fragment):
        self.text = fragment

    def render(self, context):
        return self.text

# Just for test
TestText = _Text


class Compiler(object):
    def __init__(self, template_string):
        self.template_string = template_string

    def each_fragment(self):
        for fragment in TOK_REGEX.split(self.template_string):
            if fragment:
                yield _Fragment(fragment)

    def compile(self):
        root = _Root()
        scope_stack = [root]
        for fragment in self.each_fragment():
            parent_scope = scope_stack[-1]
            if fragment.type == CLOSE_BLOCK_FRAGMENT:
                scope_stack.pop()
                continue
            new_node = self.create_node(fragment)
            if new_node:
                parent_scope.children.append(new_node)
                if new_node.creates_scope:
                    scope_stack.append(new_node)
        return root

    def create_node(self, fragment):
        node_class = None
        if fragment.type == TEXT_FRAGMENT:
            node_class = _Text
        elif fragment.type == VAR_FRAGMENT:
            node_class = _Variable
        elif fragment.type == OPEN_BLOCK_FRAGMENT:
            cmd = fragment.text.split()[0]
            if cmd == 'each':
                node_class = _Each
        # TODO
        # if node_class is None:
        #    raise TemplateSyntaxError(fragment)
        return node_class(fragment.text)


class Template(object):
    def __init__(self, contents):
        self.root = Compiler(contents).compile()

    def render(self, **kwargs):
        return self.root.render(kwargs)
