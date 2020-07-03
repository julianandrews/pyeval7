# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython

cdef class Card:
    cdef public unsigned long long mask

cdef unsigned long long cards_to_mask(py_cards)
