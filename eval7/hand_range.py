from __future__ import absolute_import

from . import range_string


class HandRange:
    def __init__(self, s):
        self.string = s
        self.tokens = range_string.string_to_tokens(s)
        self.hands = range_string.string_to_hands(s)

    def __iter__(self):
        for x in self.hands:
            yield x

    def __len__(self):
        return len(self.hands)
