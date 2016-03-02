import re

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
    def __init__(self, fragment):
        pass

class _Each(_Node):
    pass

# Just for test
TestEach = _Each

class _Text(_Node):
    pass

# Just for test
TestText = _Text

class _Variable(_Node):
    pass

# Just for test
TestVariable = _Variable

class Compiler(object):
    def __init__(self, template_string):
        self.template_string = template_string

    def each_fragment(self):
        for fragment in TOK_REGEX.split(self.template_string):
            if fragment:
                yield _Fragment(fragment)

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

