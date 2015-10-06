from __future__ import absolute_import

from . import rangestring


class HandRange:
    """A weighted range of hands, initialized from a range string.

    Examples:
        hr = HandRange('55+, 87o, K9s-KJs')
        hr = HandRange('JJ+, AT+, 80%(A8s+)')
    """
    def __init__(self, s):
        self.string = s
        self.tokens = rangestring.string_to_tokens(s)
        self.hands = rangestring.string_to_hands(s)

    def __iter__(self):
        for x in self.hands:
            yield x

    def __len__(self):
        return len(self.hands)
