# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython

ranks = ('2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A')
suits = ('c', 'd', 'h', 's')

cdef class Card:
    def __init__(self, card_string):
        self.rank = ranks.index(card_string[0])
        self.suit = suits.index(card_string[1])
        self.mask = (<cython.ulonglong>1) << \
                (<cython.ulonglong>(13*self.suit + self.rank))

    property rank:
        def __get__(self):
            return self.rank
    
    property suit:
        def __get__(self):
            return self.suit

    property mask:
        def __get__(self):
            return self.mask

    def __str__(self):
        return ranks[self.rank] + suits[self.suit]

    def __repr__(self):
        return "Card(\"{}\")".format(self.__str__())

    def __richcmp__(self, other, int op):
        if isinstance(other, Card):
            eq = self.mask == other.mask
            gt = (self.rank > other.rank) or (self.suit > other.suit)
            if op == 0:
                return not (gt or eq)
            elif op == 1:
                return not gt
            elif op == 2:
                return eq
            elif op == 3:
                return not eq
            elif op == 4:
                return gt
            else:
                return gt or eq
        else:
            if op == 2:
                return False
            elif op == 3:
                return True
            else:
                raise TypeError("Cannot compare {!r} and {!r}".format(
                    self, other))

    def __hash__(self):
        return self.mask

cdef cython.ulonglong cards_to_mask(py_cards):
    cdef cython.ulonglong cards = 0
    for py_card in py_cards:
        cards |= py_card.mask
    return cards

