# Copyright 2014 Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

from __future__ import absolute_import

import unittest

from eval7 import range_string


class RangeStringTestCase(unittest.TestCase):
    @unittest.skip('Unimplemented test')
    def test_string_to_hands(self):
        pass

    @unittest.skip('Unimplemented test')
    def test_tokens_to_string(self):
        pass

    @unittest.skip('Unimplemented test')
    def test_parser(self):
        pass

    def test_string_to_tokens(self):
        self.assertEqual(
            range_string.string_to_tokens("AA, 0.8(AKs)"),
            [('AA', 1.0), ('AKs', 0.8)]
        )

    def test_validate_string(self):
        true_cases = (
            'ATs+, 80%(22-55)',
            'ATs+,KQ, .2(4s9s)',
        )
        false_cases = (
            'ATs+, KQ, .2(4s4s)',
            'AX+',
        )
        for case in true_cases:
            self.assertTrue(range_string.validate_string(case))
        for case in false_cases:
            self.assertFalse(range_string.validate_string(case))

    def test_weight_to_float(self):
        cases = (
            (('86', '%'), 0.86),
            (('3', ), 3),
            (('0.7', ), 0.7),
            (('.1', '%'), 0.001),
            (('.1', ), 0.1),
        )
        for parsed_weight, value in cases:
            self.assertAlmostEqual(
                range_string.weight_to_float(parsed_weight), value, places=7
            )

    def test_expand_hand_type_group(self):
        cases = (
            (('ATs', '-', 'AQs'), ['ATs', 'AJs', 'AQs']),
            (('JTn', '-', 'J8n'), ['J8o', 'J8s', 'J9o', 'J9s', 'JTo', 'JTs']),
            (('55', '-', '99'), ['55', '66', '77', '88', '99']),
            (('T7o', '+'), ['T7o', 'T8o', 'T9o']),
            (('88', '+'), ['88', '99', 'TT', 'JJ', 'QQ', 'KK', 'AA']),
            (('#', 'comment'), ['#comment']),
        )

        for htg, tokens in cases:
            self.assertEqual(range_string.expand_hand_type_group(htg), tokens)

        with self.assertRaises(range_string.RangeStringError):
            range_string.expand_hand_type_group(('94o', '-', '97s'))
        with self.assertRaises(range_string.RangeStringError):
            range_string.expand_hand_type_group(('22', '-', '97s'))
        with self.assertRaises(range_string.RangeStringError):
            range_string.expand_hand_type_group(('J3s', '-', 'QQ'))

    def test_token_to_hands(self):
        cases = (
            ('ATs', [('Ac', 'Tc'), ('Ad', 'Td'), ('Ah', 'Th'), ('As', 'Ts')]),
            ('55', [('5s', '5h'), ('5s', '5d'), ('5s', '5c'), ('5h', '5d'),
                    ('5h', '5c'), ('5d', '5c')]),
            ('74o', [('7s', '4h'), ('7s', '4d'), ('7s', '4c'), ('7h', '4s'),
                     ('7h', '4d'), ('7h', '4c'), ('7d', '4s'), ('7d', '4h'),
                     ('7d', '4c'), ('7c', '4s'), ('7c', '4h'), ('7c', '4d')]),
        )

        for token, hand_strings in cases:
            self.assertEqual(
                set(range_string.token_to_hands(token)), set(hand_strings)
            )

    def test_normalize_token(self):
        cases = (
            ('ats', 'ATs'),
            ('25o', '52o'),
            ('7j', 'J7n'),
            ('qKs', 'KQs'),
            ('22', '22p'),
            ('As2d', 'As2d'),
            ('QsAc', 'AcQs'),
            ('2c2d', '2d2c'),
            ('#Comment', '#Comment'),
        )

        for token, normalized in cases:
            self.assertEqual(range_string.normalize_token(token), normalized)

        with self.assertRaises(range_string.RangeStringError):
            range_string.normalize_token('77s')

    def test_token_suitedness(self):
        cases = (
            ('ATs', 's'),
            ('Q3o', 'o'),
            ('55', 'p'),
            ('J7', 'n'),
        )

        for token, suitedness in cases:
            self.assertEqual(range_string.token_suitedness(token), suitedness)

        with self.assertRaises(range_string.RangeStringError):
            range_string.token_suitedness('22o')

suite = unittest.TestLoader().loadTestsFromTestCase(RangeStringTestCase)
