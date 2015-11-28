# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

from __future__ import absolute_import, division

import collections
import unittest

from eval7 import xorshift_rand


class XorshiftRandTestCase(unittest.TestCase):
    SAMPLE_COUNT = 1000000
    BINS = 1000
    DELTA = 150  # This should give < 1% chance of failure per test

    def check_uniform(self, counter):
        expected_count = self.SAMPLE_COUNT / self.BINS
        self.assertEqual(set(range(self.BINS)), set(counter.keys()))
        for count in counter.values():
            self.assertAlmostEqual(count, expected_count, delta=self.DELTA)

    def test_random_is_uniform(self):
        sample = (xorshift_rand.random() for i in range(self.SAMPLE_COUNT))
        counter = collections.Counter(int(num * self.BINS) for num in sample)
        self.check_uniform(counter)

    def test_randint_is_uniform(self):
        sample = (
            xorshift_rand.randint(self.BINS) for i in range(self.SAMPLE_COUNT)
        )
        self.check_uniform(collections.Counter(sample))
