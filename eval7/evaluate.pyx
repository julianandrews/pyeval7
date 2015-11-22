# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython
from cards cimport cards_to_mask


cdef extern from "arrays.h":
    cython.ushort N_BITS_TABLE[8192]
    cython.ushort STRAIGHT_TABLE[8192]
    cython.uint TOP_FIVE_CARDS_TABLE[8192]
    cython.ushort TOP_CARD_TABLE[8192]

cdef int CLUB_OFFSET = 0
cdef int DIAMOND_OFFSET = 13
cdef int HEART_OFFSET = 26
cdef int SPADE_OFFSET = 39

cdef int HANDTYPE_SHIFT = 24 
cdef int TOP_CARD_SHIFT = 16 
cdef int SECOND_CARD_SHIFT = 12 
cdef int THIRD_CARD_SHIFT = 8 
cdef int CARD_WIDTH = 4 
cdef cython.uint TOP_CARD_MASK = 0x000F0000 
cdef cython.uint SECOND_CARD_MASK = 0x0000F000 
cdef cython.uint FIFTH_CARD_MASK = 0x0000000F 

cdef cython.uint HANDTYPE_VALUE_STRAIGHTFLUSH = ((<cython.uint>8) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_FOUR_OF_A_KIND = ((<cython.uint>7) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_FULLHOUSE = ((<cython.uint>6) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_FLUSH = ((<cython.uint>5) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_STRAIGHT = ((<cython.uint>4) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_TRIPS = ((<cython.uint>3) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_TWOPAIR = ((<cython.uint>2) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_PAIR = ((<cython.uint>1) << HANDTYPE_SHIFT)
cdef cython.uint HANDTYPE_VALUE_HIGHCARD = ((<cython.uint>0) << HANDTYPE_SHIFT)


cdef cython.uint cy_evaluate(cython.ulonglong cards, cython.uint num_cards):
    """
    7-card evaluation function based on Keith Rule's port of PokerEval.
    Pure Python: 20000 calls in 0.176 seconds (113636 calls/sec)
    Cython: 20000 calls in 0.044 seconds (454545 calls/sec)
    """
    cdef cython.uint retval = 0, four_mask, three_mask, two_mask
    
    cdef cython.uint sc = <cython.uint>((cards >> (CLUB_OFFSET)) & 0x1fffUL)
    cdef cython.uint sd = <cython.uint>((cards >> (DIAMOND_OFFSET)) & 0x1fffUL)
    cdef cython.uint sh = <cython.uint>((cards >> (HEART_OFFSET)) & 0x1fffUL)
    cdef cython.uint ss = <cython.uint>((cards >> (SPADE_OFFSET)) & 0x1fffUL)
    
    cdef cython.uint ranks = sc | sd | sh | ss
    cdef cython.uint n_ranks = N_BITS_TABLE[ranks]
    cdef cython.uint n_dups = <cython.uint>(num_cards - n_ranks)
    
    cdef cython.uint st, t, kickers, second, tc, top
    
    if n_ranks >= 5:
        if N_BITS_TABLE[ss] >= 5:
            if STRAIGHT_TABLE[ss] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(STRAIGHT_TABLE[ss] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + TOP_FIVE_CARDS_TABLE[ss]
        elif N_BITS_TABLE[sc] >= 5:
            if STRAIGHT_TABLE[sc] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(STRAIGHT_TABLE[sc] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + TOP_FIVE_CARDS_TABLE[sc]
        elif N_BITS_TABLE[sd] >= 5:
            if STRAIGHT_TABLE[sd] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(STRAIGHT_TABLE[sd] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + TOP_FIVE_CARDS_TABLE[sd]
        elif N_BITS_TABLE[sh] >= 5:
            if STRAIGHT_TABLE[sh] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(STRAIGHT_TABLE[sh] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + TOP_FIVE_CARDS_TABLE[sh]
        else:
            st = STRAIGHT_TABLE[ranks]
            if st != 0:
                retval = HANDTYPE_VALUE_STRAIGHT + (st << TOP_CARD_SHIFT)

        if retval != 0 and n_dups < 3:
            return retval

    if n_dups == 0:
        return HANDTYPE_VALUE_HIGHCARD + TOP_FIVE_CARDS_TABLE[ranks]
    elif n_dups == 1:
        two_mask = ranks ^ (sc ^ sd ^ sh ^ ss)
        retval = <cython.uint>(HANDTYPE_VALUE_PAIR + (TOP_CARD_TABLE[two_mask] << TOP_CARD_SHIFT))
        t = ranks ^ two_mask
        kickers = (TOP_FIVE_CARDS_TABLE[t] >> CARD_WIDTH) & ~FIFTH_CARD_MASK
        retval += kickers
        return retval
    elif n_dups == 2:
        two_mask = ranks ^ (sc ^ sd ^ sh ^ ss)
        if two_mask != 0:
            t = ranks ^ two_mask
            retval = <cython.uint>(HANDTYPE_VALUE_TWOPAIR
                + (TOP_FIVE_CARDS_TABLE[two_mask]
                & (TOP_CARD_MASK | SECOND_CARD_MASK))
                + (TOP_CARD_TABLE[t] << THIRD_CARD_SHIFT))
            return retval
        else:
            three_mask = ((sc & sd) | (sh & ss)) & ((sc & sh) | (sd & ss))
            retval = <cython.uint>(HANDTYPE_VALUE_TRIPS + (TOP_CARD_TABLE[three_mask] << TOP_CARD_SHIFT))
            t = ranks ^ three_mask
            second = TOP_CARD_TABLE[t]
            retval += (second << SECOND_CARD_SHIFT)
            t ^= (1U << <int>second)
            retval += <cython.uint>(TOP_CARD_TABLE[t] << THIRD_CARD_SHIFT)
            return retval
    else:
        four_mask = sh & sd & sc & ss
        if four_mask != 0:
            tc = TOP_CARD_TABLE[four_mask]
            retval = <cython.uint>(HANDTYPE_VALUE_FOUR_OF_A_KIND
                + (tc << TOP_CARD_SHIFT)
                + ((TOP_CARD_TABLE[ranks ^ (1U << <int>tc)]) << SECOND_CARD_SHIFT))
            return retval
        two_mask = ranks ^ (sc ^ sd ^ sh ^ ss)
        if N_BITS_TABLE[two_mask] != n_dups:
            three_mask = ((sc & sd) | (sh & ss)) & ((sc & sh) | (sd & ss))
            retval = HANDTYPE_VALUE_FULLHOUSE
            tc = TOP_CARD_TABLE[three_mask]
            retval += (tc << TOP_CARD_SHIFT)
            t = (two_mask | three_mask) ^ (1U << <int>tc)
            retval += <cython.uint>(TOP_CARD_TABLE[t] << SECOND_CARD_SHIFT)
            return retval
        if retval != 0:
            return retval
        else:
            retval = HANDTYPE_VALUE_TWOPAIR
            top = TOP_CARD_TABLE[two_mask]
            retval += (top << TOP_CARD_SHIFT)
            second = TOP_CARD_TABLE[two_mask ^ (1 << <int>top)]
            retval += (second << SECOND_CARD_SHIFT)
            retval += <cython.uint>((TOP_CARD_TABLE[ranks ^ (1U << <int>top) ^ (1 << <int>second)]) << THIRD_CARD_SHIFT)
            return retval


def evaluate(py_cards):
    """
    evaluate(cards) -> value

    Evaluate a poker hand and produce a numeric value. Higher numeric values
    indicate stronger hands. 'cards' should be a sequence of 5 to 7 eval7.Card
    objects.
    """
    cdef cython.ulonglong mask = cards_to_mask(py_cards)
    cdef cython.uint strength = cy_evaluate(mask, len(py_cards))
    return strength

cpdef handtype(cython.uint value):
    cdef cython.uint ht = (value >> HANDTYPE_SHIFT)
    if ht == HANDTYPE_VALUE_HIGHCARD >> HANDTYPE_SHIFT:
        return "High Card"
    elif ht == HANDTYPE_VALUE_PAIR >> HANDTYPE_SHIFT:
        return "Pair"
    elif ht == HANDTYPE_VALUE_TWOPAIR >> HANDTYPE_SHIFT:
        return "Two Pair"
    elif ht == HANDTYPE_VALUE_TRIPS >> HANDTYPE_SHIFT:
        return "Trips"
    elif ht == HANDTYPE_VALUE_STRAIGHT >> HANDTYPE_SHIFT:
        return "Straight"
    elif ht == HANDTYPE_VALUE_FLUSH >> HANDTYPE_SHIFT:
        return "Flush"
    elif ht == HANDTYPE_VALUE_FULLHOUSE >> HANDTYPE_SHIFT:
        return "Full House"
    elif ht == HANDTYPE_VALUE_FOUR_OF_A_KIND >> HANDTYPE_SHIFT:
        return "Quads"
    else:
        return "Straight Flush"
