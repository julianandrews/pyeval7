# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython

cdef class Card:
    cdef public cython.ulonglong mask
    cdef public cython.ushort rank, suit

cdef cython.ulonglong cards_to_mask(py_cards)
