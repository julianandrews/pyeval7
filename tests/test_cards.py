# Copyright 2020 Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import unittest

import eval7
import pickle

class TestCards(unittest.TestCase):
    def test_suits(self):
        for rank in eval7.ranks:
            for i, suit in enumerate(eval7.suits):
                card = eval7.Card(rank + suit)
                self.assertEqual(card.suit, i)

    def test_ranks(self):
        for i, rank in enumerate(eval7.ranks):
            for suit in eval7.suits:
                card = eval7.Card(rank + suit)
                self.assertEqual(card.rank, i)

    def test_pickle(self):
        for i, rank in enumerate(eval7.ranks):
            for suit in eval7.suits:
                card = eval7.Card(rank + suit)
                pickled = pickle.dumps(card)
                card2 = pickle.loads(pickled)
                self.assertEqual(card, card2)
