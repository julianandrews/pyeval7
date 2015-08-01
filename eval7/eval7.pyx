# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

import cython
from cards cimport cards_to_mask


cdef extern from "arrays.h":
    cython.ushort n_bits_table[8192]
    cython.ushort straight_table[8192]
    cython.uint top_five_cards_table[8192]
    cython.ushort top_card_table[8192]

cdef cython.int Spades = 3
cdef cython.int Hearts = 2
cdef cython.int Diamonds = 1
cdef cython.int Clubs = 0

cdef cython.int SPADE_OFFSET = 13 * Spades
cdef cython.int CLUB_OFFSET = 13 * Clubs
cdef cython.int DIAMOND_OFFSET = 13 * Diamonds
cdef cython.int HEART_OFFSET = 13 * Hearts

cdef cython.int HANDTYPE_SHIFT = 24 
cdef cython.int TOP_CARD_SHIFT = 16 
cdef cython.uint TOP_CARD_MASK = 0x000F0000 
cdef cython.int SECOND_CARD_SHIFT = 12 
cdef cython.uint SECOND_CARD_MASK = 0x0000F000 
cdef cython.int THIRD_CARD_SHIFT = 8 
cdef cython.int FOURTH_CARD_SHIFT = 4 
cdef cython.int FIFTH_CARD_SHIFT = 0 
cdef cython.uint FIFTH_CARD_MASK = 0x0000000F 
cdef cython.int CARD_WIDTH = 4 
cdef cython.uint CARD_MASK = 0x0F 
cdef cython.int NUMBER_OF_CARDS = 52 

cdef cython.uint HANDTYPE_STRAIGHTFLUSH = (<cython.uint>8)
cdef cython.uint HANDTYPE_FOUR_OF_A_KIND = (<cython.uint>7)
cdef cython.uint HANDTYPE_FULLHOUSE = (<cython.uint>6)
cdef cython.uint HANDTYPE_FLUSH = (<cython.uint>5)
cdef cython.uint HANDTYPE_STRAIGHT = (<cython.uint>4)
cdef cython.uint HANDTYPE_TRIPS = (<cython.uint>3)
cdef cython.uint HANDTYPE_TWOPAIR = (<cython.uint>2)
cdef cython.uint HANDTYPE_PAIR = (<cython.uint>1)
cdef cython.uint HANDTYPE_HIGHCARD = (<cython.uint>0)

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
    cdef cython.uint n_ranks = n_bits_table[ranks]
    cdef cython.uint n_dups = <cython.uint>(num_cards - n_ranks)
    
    cdef cython.uint st, t, kickers, second, tc, top
    
    if n_ranks >= 5:
        if n_bits_table[ss] >= 5:
            if straight_table[ss] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(straight_table[ss] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + top_five_cards_table[ss]
        elif n_bits_table[sc] >= 5:
            if straight_table[sc] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(straight_table[sc] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + top_five_cards_table[sc]
        elif n_bits_table[sd] >= 5:
            if straight_table[sd] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(straight_table[sd] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + top_five_cards_table[sd]
        elif n_bits_table[sh] >= 5:
            if straight_table[sh] != 0:
                return HANDTYPE_VALUE_STRAIGHTFLUSH + <cython.uint>(straight_table[sh] << TOP_CARD_SHIFT)
            else:
                retval = HANDTYPE_VALUE_FLUSH + top_five_cards_table[sh]
        else:
            st = straight_table[ranks]
            if st != 0:
                retval = HANDTYPE_VALUE_STRAIGHT + (st << TOP_CARD_SHIFT)

        if retval != 0 and n_dups < 3:
            return retval

    if n_dups == 0:
        return HANDTYPE_VALUE_HIGHCARD + top_five_cards_table[ranks]
    elif n_dups == 1:
        two_mask = ranks ^ (sc ^ sd ^ sh ^ ss)
        retval = <cython.uint>(HANDTYPE_VALUE_PAIR + (top_card_table[two_mask] << TOP_CARD_SHIFT))
        t = ranks ^ two_mask
        kickers = (top_five_cards_table[t] >> CARD_WIDTH) & ~FIFTH_CARD_MASK
        retval += kickers
        return retval
    elif n_dups == 2:
        two_mask = ranks ^ (sc ^ sd ^ sh ^ ss)
        if two_mask != 0:
            t = ranks ^ two_mask
            retval = <cython.uint>(HANDTYPE_VALUE_TWOPAIR
                + (top_five_cards_table[two_mask]
                & (TOP_CARD_MASK | SECOND_CARD_MASK))
                + (top_card_table[t] << THIRD_CARD_SHIFT))
            return retval
        else:
            three_mask = ((sc & sd) | (sh & ss)) & ((sc & sh) | (sd & ss))
            retval = <cython.uint>(HANDTYPE_VALUE_TRIPS + (top_card_table[three_mask] << TOP_CARD_SHIFT))
            t = ranks ^ three_mask
            second = top_card_table[t]
            retval += (second << SECOND_CARD_SHIFT)
            t ^= (1U << <cython.int>second)
            retval += <cython.uint>(top_card_table[t] << THIRD_CARD_SHIFT)
            return retval
    else:
        four_mask = sh & sd & sc & ss
        if four_mask != 0:
            tc = top_card_table[four_mask]
            retval = <cython.uint>(HANDTYPE_VALUE_FOUR_OF_A_KIND
                + (tc << TOP_CARD_SHIFT)
                + ((top_card_table[ranks ^ (1U << <cython.int>tc)]) << SECOND_CARD_SHIFT))
            return retval
        two_mask = ranks ^ (sc ^ sd ^ sh ^ ss)
        if n_bits_table[two_mask] != n_dups:
            three_mask = ((sc & sd) | (sh & ss)) & ((sc & sh) | (sd & ss))
            retval = HANDTYPE_VALUE_FULLHOUSE
            tc = top_card_table[three_mask]
            retval += (tc << TOP_CARD_SHIFT)
            t = (two_mask | three_mask) ^ (1U << <cython.int>tc)
            retval += <cython.uint>(top_card_table[t] << SECOND_CARD_SHIFT)
            return retval
        if retval != 0:
            return retval
        else:
            retval = HANDTYPE_VALUE_TWOPAIR
            top = top_card_table[two_mask]
            retval += (top << TOP_CARD_SHIFT)
            second = top_card_table[two_mask ^ (1 << <cython.int>top)]
            retval += (second << SECOND_CARD_SHIFT)
            retval += <cython.uint>((top_card_table[ranks ^ (1U << <cython.int>top) ^ (1 << <cython.int>second)]) << THIRD_CARD_SHIFT)
            return retval


def evaluate(py_cards):
    cdef cython.ulonglong mask = cards_to_mask(py_cards)
    cdef cython.uint strength = cy_evaluate(mask, len(py_cards))
    return strength

cpdef hand_type(cython.uint value):
    cdef cython.uint ht = (value >> HANDTYPE_SHIFT)
    if ht == HANDTYPE_HIGHCARD:
        return "High Card"
    elif ht == HANDTYPE_PAIR:
        return "Pair"
    elif ht == HANDTYPE_TWOPAIR:
        return "Two Pair"
    elif ht == HANDTYPE_TRIPS:
        return "Trips"
    elif ht == HANDTYPE_STRAIGHT:
        return "Straight"
    elif ht == HANDTYPE_FLUSH:
        return "Flush"
    elif ht == HANDTYPE_FULLHOUSE:
        return "Full House"
    elif ht == HANDTYPE_FOUR_OF_A_KIND:
        return "Quads"
    else:
        return "Straight Flush"
