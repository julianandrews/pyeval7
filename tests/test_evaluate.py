# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import unittest
import eval7


class TestEvaluate(unittest.TestCase):
    def test_hand_to_mask(self):
        # Highest and lowest cards
        cards = [eval7.Card(x) for x in ("As", "2c")]
        result = cards[0].mask | cards[1].mask
        self.assertEqual(result, 2251799813685249)

    def test_evaluate(self):
        cases = (
            (['2c', '3d', '4h', '5s', '7s', '8d', '9c'], 484658, 'High Card'),
            (['2c', '3d', '4h', '4s', '7s', '8d', '9c'], 16938576, 'Pair'),
            (['2c', '3d', '4h', '4s', '7s', '7d', '9c'], 33892096, 'Two Pair'),
            (['2c', '3d', '4h', '7s', '7c', '7d', '9c'], 50688512, 'Trips'),
            (['2c', '3d', '4h', '5s', '7c', '7d', '6c'], 67436544, 'Straight'),
            (['Ac', '3h', '4h', '5s', '2h', 'Jh', 'Kd'], 67305472, 'Straight'),
            (['Ac', '3h', 'Th', '5s', 'Qh', 'Jh', 'Kd'], 67895296, 'Straight'),
            (['2c', '3h', '4h', '5s', 'Jh', '7h', '6h'], 84497441, 'Flush'),
            (['Ac', '3h', 'Th', 'Ts', 'Ks', 'Kh', 'Kd'], 101416960, 'Full House'),
            (['Ac', '3h', 'Th', 'Ks', 'Kh', 'Kd', 'Kc'], 118210560, 'Quads'),
            (['3c', '2c', '5c', 'Ac', '4c', 'Kd', 'Kc'], 134414336, 'Straight Flush'),
        )
        for card_strs, expected_val, expected_type in cases:
            cards = tuple(map(eval7.Card, card_strs))
            value = eval7.evaluate(cards)
            handtype = eval7.handtype(value)
            self.assertEqual(value, expected_val)
            self.assertEqual(handtype, expected_type)


if __name__ == '__main__':
    # 2013-02-09 28 seconds
    unittest.main()
