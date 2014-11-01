# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython
import time

cdef int _wh_seed_x, _wh_seed_y, _wh_seed_z

cdef void wh_init(cython.ulong seed):
    """Initialize internal state from hashable object.
    
    None or no argument seeds from current time or from an operating
    system specific randomness source if available.
    
    If a is not None or an int or long, hash(a) is used instead.
    
    If a is an int or long, a is used directly.  Distinct values between
    0 and 27814431486575L inclusive are guaranteed to yield distinct
    internal states (this guarantee is specific to the default
    Wichmann-Hill generator).
    """
    global _wh_seed_x, _wh_seed_y, _wh_seed_z
    # arbitrarily, statically chosen for this eval7 version.
    cdef cython.ulong a = seed
    _wh_seed_x = a % 30268; a = a / 30268 
    _wh_seed_y = a % 30306; a = a / 30306
    _wh_seed_z = a % 30322

cdef cython.double wh_random():
    """Get the next random number in the range [0.0, 1.0)."""
    # Wichman-Hill random number generator.
    #
    # Wichmann, B. A. & Hill, I. D. (1982)
    # Algorithm AS 183:
    # An efficient and portable pseudo-random number generator
    # Applied Statistics 31 (1982) 188-190
    #
    # see also:
    #        Correction to Algorithm AS 183
    #        Applied Statistics 33 (1984) 123
    #
    #        McLeod, A. I. (1985)
    #        A remark on Algorithm AS 183
    #        Applied Statistics 34 (1985),198-200
    global _wh_seed_x, _wh_seed_y, _wh_seed_z
    # This part is thread-unsafe:
    # BEGIN CRITICAL SECTION
    _wh_seed_x = (171 * _wh_seed_x) % 30269
    _wh_seed_y = (172 * _wh_seed_y) % 30307
    _wh_seed_z = (170 * _wh_seed_z) % 30323
    # END CRITICAL SECTION
    # Note:  on a platform using IEEE-754 double arithmetic, this can
    # never return 0.0 (asserted by Tim; proof too long for a comment).
    return (_wh_seed_x/30269.0 + _wh_seed_y/30307.0 + _wh_seed_z/30323.0) % 1.0

cdef cython.int wh_randint(cython.int r):
    # wh_random() is 0.0 < x <= 1.0
    # 1 - wh_random() is 0.0 <= x < 1.0
    # (1 - wh_random()) * range is 0.0 <= x < range
    # <cython.int>((1 - wh_random()) * range) is a fairly evenly distributed integer 0 <= x < range
    return <cython.int>((1 - wh_random()) * r)

def py_wh_randint(r):
    return wh_randint(r)

wh_init(time.time())  # Python code, but done only once

