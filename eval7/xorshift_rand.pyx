# Copyright 2015 Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#
# Algorithm from:
#   https://en.wikipedia.org/w/index.php?title=Xorshift&oldid=687473210

import cython

__all__ = ["init", "randint"]

cdef cython.ulong _seed[16]
cdef int _seed_index;


cdef void cy_init(cython.ulong seed):
    """Use xorshift64* with a 64 bit seed to generate a 1024 bit seed.

    Obviously this limits the number of possible seeds, but should be
    good enough for most practical purposes."""
    global _seed, _seed_index
    _seed[0] = seed
    _seed_index = 0
    for i in range(15):
        _seed[i + 1] = _seed[i] ^ (_seed[i] >> 12)
        _seed[i + 1] = _seed[i + 1] ^ (_seed[i + 1]  << 25)
        _seed[i + 1] = _seed[i + 1] ^ (_seed[i + 1]  >> 27)
        _seed[i + 1] = _seed[i + 1] * <cython.ulong>(2685821657736338717)
    

cdef cython.ulong next_rand():
    """Return a random ulong using xorshift1024*."""
    global _seed, _seed_index
    cdef cython.ulong s0, s1

    s0 = _seed[_seed_index];
    _seed_index = (_seed_index + 1) & 15
    s1 = _seed[_seed_index];
    s1 = s1 ^ (s1 << 31)
    s1 = s1 ^ (s1 >> 11)
    s0 = s0 ^ (s0 >> 30)
    _seed[_seed_index] = s0 ^ s1

    return _seed[_seed_index] * <cython.ulong>(1181783497276652981)


cdef int cy_randint(int n):
    """Return a random integer 0 <= x < n.
    
    Reject an apropriate fraction of samples to avoid bias. The loop should
    take an average of fewer than 2 iterations even in the worst case."""
    cdef cython.ulong r
    cdef int val

    while True:
        r = next_rand()
        val = r % n
        if r - val + n - 1 >= 0:  
            return val


def init(seed=None):
    """Seed the random number generator.
    
    Seed must be castable to long. Defaults to seeding with time.time()"""
    import time
    import struct
    if seed is None:
        seed = struct.unpack('q', struct.pack('d', time.time()))[0]
    del time
    del struct

    cy_init(long(seed))


def randint(int n):
    """Generate a random integer 0 <= x < n."""
    return cy_randint(n)


init()
