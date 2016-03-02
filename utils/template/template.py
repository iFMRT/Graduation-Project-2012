import re

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

class Compiler(object):
    def __init__(self, template_string):
        self.template_string = template_string

    def each_fragment(self):
        for fragment in TOK_REGEX.split(self.template_string):
            if fragment:
                yield fragment
