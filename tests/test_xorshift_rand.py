# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

from __future__ import absolute_import, division

import collections
import unittest

import eval7.xorshift_rand


class XorshiftRandTestCase(unittest.TestCase):
    SAMPLE_RANGE = 52
    SAMPLE_COUNT = 36500 * SAMPLE_RANGE
    DELTA = 1000

    def setUp(self):
        self.results = collections.Counter(
            eval7.xorshift_rand.randint(self.SAMPLE_RANGE)
            for i in range(self.SAMPLE_COUNT)
        )

    def test_randint_in_range(self):
        allowed_values = list(range(52))
        for i in self.results:
            self.assertIn(i, allowed_values)

    def test_randint_is_uniform(self):
        expected_count = self.SAMPLE_COUNT / self.SAMPLE_RANGE
        for i in range(self.SAMPLE_RANGE):
            self.assertAlmostEqual(
                self.results.get(i, 0), expected_count, delta=self.DELTA
            )
