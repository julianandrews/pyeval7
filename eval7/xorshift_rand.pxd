# Copyright 2015 Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython

cdef void cy_seed(cython.ulong seed)
cpdef int randint(int n)
