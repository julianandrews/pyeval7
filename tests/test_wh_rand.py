# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

from __future__ import absolute_import, division

import unittest
from collections import Counter

import eval7.wh_rand


class WhRandTestCase(unittest.TestCase):
    SAMPLE_RANGE = 52
    SAMPLE_COUNT = 36500 * SAMPLE_RANGE
    DELTA = 1000

    def setUp(self):
        self.results = Counter(eval7.wh_rand.py_wh_randint(self.SAMPLE_RANGE)
                               for i in range(self.SAMPLE_COUNT))

    def test_rand_int_in_range(self):
        allowed_values = list(range(52))
        for i, count in self.results.items():
            self.assertIn(i, allowed_values)

    def test_rand_int_is_uniform(self):
        expected_count = self.SAMPLE_COUNT / self.SAMPLE_RANGE
        for i in range(self.SAMPLE_RANGE):
            self.assertIn(i, self.results)
            self.assertAlmostEqual(
                self.results[i], expected_count, delta=self.DELTA
            )

suite = unittest.TestLoader().loadTestsFromTestCase(WhRandTestCase)
