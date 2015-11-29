# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython
import random


ranks = ('2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A')
suits = ('c', 'd', 'h', 's')


cdef class Card:
    """
    A card with a rank and suit, initialized from a string, and with an
    integer 'mask' value used for evaluation and equity calcuations.

    Example:
        cards = map(Card, ('As', '4d', '4c', '3s', '2d'))
        eval7.evaluate(cards)
    """
    def __init__(self, card_string):
        self.rank = ranks.index(card_string[0])
        self.suit = suits.index(card_string[1])
        self.mask = (<unsigned long long>1) << (13*self.suit + self.rank)

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


class Deck:
    """
    A set of all 52 distinct cards, pregenerated to minimize overhead.
    Also provides a few convenience methods for simple simulations.
    """
    def __init__(self):
        """
        Create a new deck object.

        Usage:
            d = Deck()
        """
        self.cards = []
        for rank in ranks:
            for suit in suits:
                card = Card(rank+suit)
                self.cards.append(card)

    def __repr__(self):
        return "Deck({})".format(self.cards)

    def __len__(self):
        return len(self.cards)

    def __getitem__(self, i):
        return self.cards[i]

    def shuffle(self):
        """Randomize the order of the cards in the deck."""
        random.shuffle(self.cards)
        
    def deal(self, n):
        """Remove the top n cards from the deck and return them."""
        if n> len(self.cards):
            raise ValueError("Insufficient cards in deck")
        dealt = self.cards[:n]
        del self.cards[:n]
        return dealt

    def peek(self, n):
        """Return the top n cards from the deck without altering it."""
        if n> len(self.cards):
            raise ValueError("Insufficient cards in deck")
        return self.cards[:n]

    def sample(self, n):
        """Return n random cards from the deck. The deck will be unaltered."""
        if n> len(self.cards):
            raise ValueError("Insufficient cards in deck")        
        return random.sample(self.cards, n)


cdef unsigned long long cards_to_mask(py_cards):
    cdef unsigned long long cards = 0
    for py_card in py_cards:
        cards |= py_card.mask
    return cards
