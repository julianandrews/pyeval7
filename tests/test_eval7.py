# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import unittest
import eval7


class TestEval7(unittest.TestCase):
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
            hand_type = eval7.hand_type(value)
            self.assertEqual(value, expected_val)
            self.assertEqual(hand_type, expected_type)

    def test_hand_vs_range_exact(self):
        cases = (
            (("Ac", "Ah"), "AA", ("Kh", "Jd", "8c", "5d", "2s"), 0.5),
            (("Ac", "Ah"), "AsAd", ("Kh", "Jd", "8c", "5d", "2s"), 0.5),
            (("As", "Ad"), "AA, A3o, 32s", ("Kh", "Jd", "8c", "5d", "2s"), 0.95),
        )
        for hand_strs, range_str, board_strs, expected_equity in cases:
            hand = tuple(map(eval7.Card, hand_strs))
            villain = eval7.HandRange(range_str)
            board = tuple(map(eval7.Card, board_strs))
            equity = eval7.py_hand_vs_range_exact(hand, villain, board)
            self.assertAlmostEqual(equity, expected_equity, places=7)

    def test_hand_vs_range_monte_carlo(self):
        hand = map(eval7.Card, ("As", "Ad"))
        villain = eval7.HandRange("AA, A3o, 32s")
        board = []
        equity = eval7.py_hand_vs_range_monte_carlo(
            hand, villain, board, 10000000
        )
        self.assertAlmostEqual(equity, 0.85337, delta=0.002)

    def test_all_hands_vs_range(self):
        hero = eval7.HandRange("AsAd, 3h2c")
        villain = eval7.HandRange("AA, A3o, 32s")
        board = []
        equity_map = eval7.py_all_hands_vs_range(hero, villain, board, 10000000)
        self.assertEqual(len(equity_map), 2)
        hand1 = tuple(map(eval7.Card, ("As", "Ad")))
        hand2 = tuple(map(eval7.Card, ("3h", "2c")))
        self.assertAlmostEqual(equity_map[hand1], 0.85337, delta=0.002)
        self.assertAlmostEqual(equity_map[hand2], 0.22865, delta=0.002)

        # Hero has an impossible hand in his range.
        hero = eval7.HandRange("JsJc,QsJs")
        villain = eval7.HandRange("JJ")
        board = tuple(map(eval7.Card, ("Kh", "Jd", "8c")))
        equity_map = eval7.py_all_hands_vs_range(hero, villain, board, 10000000)
        hand = tuple(map(eval7.Card, ("Qs", "Js")))
        self.assertAlmostEqual(equity_map[hand], 0.03687, delta=0.0002)
        self.assertEqual(len(equity_map), 1)


if __name__ == '__main__':
    # 2013-02-09 28 seconds
    unittest.main()
