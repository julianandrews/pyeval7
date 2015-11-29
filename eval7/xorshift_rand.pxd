# Copyright 2015 Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython

cdef void cy_seed(unsigned long seed)
cpdef int randint(int n)
cpdef double random()
