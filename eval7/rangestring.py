# Copyright 2014 Anonymous7 from Reddit, Julian Andrews
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

"""Parser for modified Pokerstove style range strings.

A range string is a comma separated list of hand type tokens, individual hands,
or tags (which are ignored by the parser). e.g.:
    ATo, 86s, JT, 99
    As3c, 8c5s
    #UTG#, #My_Tag#

Tokens with similar suitedness can be grouped. e.g.:
    88-JJ => 88, 99, TT, JJ
    A7o-ATo => A7o, A8o, A9o, ATo
    T6s+ => T6s, T7s, T8s, T9s

Groups of tokens can be combined with a weight. e.g.:
    0.6(AA, AK)
    40%(ATs+)

Examples:
    string_to_tokens("AA, 0.8(AKs)") = [('AA', 1.0), ('AKs', 0.8)]
    tokens_to_string([('AA', 1.0), ('AQs', 1.0), ('AJs', 1.0)]) = 'AA, AQs-AJs'
    validate_string("TT+, A8o-ATo, 80%(KTs+)") = True
"""

import pyparsing
from .cards import Card, ranks, suits


def string_to_hands(s):
    """Parse a handstring and return a list of (hand, weight) tuples."""
    hands = []
    for token, weight in string_to_tokens(s):
        hands += [(tuple(map(Card, hand)), weight)
                  for hand in token_to_hands(token)]
    return hands


def string_to_tokens(s):
    """Parse a handstring and return a list of (token, weight) tuples."""
    tokens = []
    try:
        results = parser.parseString(s)
    except pyparsing.ParseException:
        raise RangeStringError("Failed to parse string")
    for r in results:
        if len(r) == 2:
            weight = weight_to_float(r[0])
            htgs = r[1]
        else:
            weight = 1.0
            htgs = r[0]
        tokens += [(token, weight) for token in
                   sum(map(expand_handtype_group, htgs), [])]
    return tokens


def tokens_to_string(tokens):
    """Take a list of (token, weight) tuples and return a handstring"""
    def t_to_s_helper(tokens, weight):

        def group(toks):
            if len(toks) <= 1:
                return toks
            strs = []
            groups = []
            bot = toks[0]
            for t1, t2 in zip(toks[:-1], toks[1:]):
                if ranks.index(t2[1]) - ranks.index(t1[1]) > 1:
                    if t1 == bot:
                        groups.append((bot, ))
                    else:
                        groups.append((bot, t1))
                    bot = t2
            if bot == t2:
                groups.append((t2, ))
            else:
                groups.append((bot, t2))
            for g in groups:
                if len(g) == 1:
                    strs.append(g[0])
                elif g[-1] == 'AA' or \
                        ranks.index(g[-1][0]) - 1 == ranks.index(g[-1][1]):
                    strs.append("{}+".format(g[0]))
                else:
                    strs.append("{}-{}".format(*reversed(g)))
            return strs

        tokens = [normalize_token(t) for (t, w) in tokens if w == weight]
        pairs = []
        single_hands = []
        other = []
        tags = []
        for t in tokens:
            if t[0] == '#':
                tags.append(t)
            elif t[-1] == 'p':
                pairs.append(t[:-1])
            elif len(t) == 4:
                single_hands.append(t)
            else:
                other.append(t)
        pairs.sort(key=lambda x: ranks.index(x[0]))
        pair_strings = group(pairs)
        pair_strings.reverse()
        single_hands.sort(key=lambda s: (ranks.index(s[0]), ranks.index(s[2]),
            suits.index(s[1]), suits.index(s[3])), reverse=True)
        other_strings = []
        for rank in ranks:
            for suitedness in ('o', 's', 'n'):
                filt = [x for x in other
                        if x[0] == rank and
                        token_suitedness(x) == suitedness and
                        ranks.index(x[0]) > ranks.index(x[1])]
                filt.sort(key=lambda x: ranks.index(x[1]))
                other_strings += group(filt)
        other_strings.reverse()
        return ', '.join(pair_strings + other_strings + single_hands + tags)

    strs = []
    weights = list(set([w for (t, w) in tokens]))
    if 1.0 in weights:
        strs.append(t_to_s_helper(tokens, 1.0))
        weights.remove(1.0)
    weights.sort(reverse=True)
    strs += ["{}%({})".format(int(100*w), t_to_s_helper(tokens, w))
             for w in weights]
    return ', '.join(strs)


def validate_string(s):
    """Return true if s is a parseable range string"""
    try:
        string_to_tokens(s)
    except RangeStringError:
        return False
    return True


def make_parser():
    """Generate the pyparsing parser for hand strings."""
    ranks_str = ''.join(ranks)
    ranks_str += ranks_str.lower()
    suits_str = ''.join(suits)
    suits_str += suits_str.lower()
    suitedness = pyparsing.Word("os", exact=1).setName("suitedness")
    card = pyparsing.Word(ranks_str, suits_str, exact=2).setName("card")
    hand = card*2
    hand.setParseAction(lambda s, loc, toks: ''.join(toks))
    digits = pyparsing.Word(pyparsing.nums)
    natural_number = pyparsing.Word('123456789', pyparsing.nums)
    decimal = natural_number ^ \
        (pyparsing.Optional(pyparsing.Literal('0')) +
         pyparsing.Literal('.') + digits) ^ \
        (natural_number + pyparsing.Literal('.') + digits) ^ \
        (natural_number + pyparsing.Literal('.'))
    decimal.setParseAction(lambda s, loc, toks: ''.join(toks))
    weight = pyparsing.Group(
        decimal + pyparsing.Optional(pyparsing.Literal('%'))
    )
    handtype = pyparsing.Word(ranks_str, exact=2) + \
        pyparsing.Optional(suitedness) + \
        ~pyparsing.FollowedBy(pyparsing.Literal('%') ^ pyparsing.Literal('('))
    handtype.setParseAction(lambda s, loc, toks: ''.join(toks))
    tag = pyparsing.Literal('#') + pyparsing.Word(pyparsing.alphanums + '_') \
        + pyparsing.Literal('#')
    handtype_group = pyparsing.Group(
        handtype ^
        (handtype + pyparsing.Literal('-') + handtype) ^
        (handtype + pyparsing.Literal('+')) ^ hand ^ tag
    )
    hand_group_list = pyparsing.Group(pyparsing.delimitedList(handtype_group))
    weighted_hand_group_list = pyparsing.Group(
        (weight + pyparsing.Literal('(').suppress() + hand_group_list +
         pyparsing.Literal(')').suppress()) ^ hand_group_list
    )
    handrange = pyparsing.Optional(pyparsing.delimitedList(
        weighted_hand_group_list)) + pyparsing.StringEnd()
    return handrange


def weight_to_float(w):
    """Take a parsed weight list and return a float. e.g.:
        ["86", "%"] -> 0.86
    """
    r = float(w[0])
    if w[-1] == '%':
        r /= 100.0
    return r


def expand_handtype_group(htg):
    """Take a parsed hand type grouping such as ('ATs', '+') or
    ('K8o', '-', 'KJo') and return a list of hand type tokens. e.g.:
        ('ATs', '-', 'AQs') -> ["ATs", "AJs", "AQs"]
    """
    tokens = []

    def sorted_ranks(token):
        return sorted(map(ranks.index, token[:2]), reverse=True)

    if htg[0] == "#":
        tokens = [''.join(htg)]
    elif len(htg) == 1:
        tokens = [normalize_token(htg[0])]
    else:
        suitedness = token_suitedness(htg[0])
        if htg[-1] == '+':
            token = normalize_token(htg[0])
            bot = sorted_ranks(token)
            top = (12, 12) if suitedness == 'p' else (bot[0], bot[0]-1)
        elif htg[1] == '-':
            if not suitedness == token_suitedness(htg[2]):
                raise RangeStringError("Suitedness mismatch: '{}' '{}'".format(
                    htg[0], htg[2]))
            bot_tok = normalize_token(htg[0])
            top_tok = normalize_token(htg[2])
            bot = sorted_ranks(bot_tok)
            top = sorted_ranks(top_tok)
            if top[1] < bot[1]:
                old_bot = bot[:]
                bot = top
                top = old_bot
        if suitedness != 'p' and not top[0] == bot[0]:
            raise RangeStringError("Top card mismatch: '{}' '{}'".format(
                htg[0], htg[2]))
        for i in range(bot[1], top[1]+1):
            ixs = (i, i) if suitedness == 'p' else (top[0], i)
            token = ''.join((ranks[j] for j in ixs))
            token += suitedness
            tokens.append(token)

    expanded = []
    for token in tokens:
        if len(token) < 4:
            base = token[:2]
            suitedness = token[-1]
            if suitedness == 'n':
                expanded.append(base + 'o')
                expanded.append(base + 's')
            elif suitedness == 'p':
                expanded.append(base)
            else:
                expanded.append(token)
        else:
            expanded.append(token)
    return expanded


def normalize_token(token):
    if token[0] == '#':
        # Comment
        normalized = token
    elif len(token) == 4:
        # Single hand (e.g.: 7c3d)
        rs = [ranks.index(x) for x in (token[0].upper(), token[2].upper())]
        suit_ranks = [suits.index(x) for x in (token[1], token[3])]
        if rs[0] == rs[1] and suit_ranks[0] == suit_ranks[1]:
            raise RangeStringError("Invalid Token: {}".format(token))
        if rs[0] < rs[1] or \
                (rs[0] == rs[1] and suit_ranks[0] < suit_ranks[1]):
            normalized = token[2:] + token[:2]
        else:
            normalized = token
    else:
        # Normal token (e.g.: 22, ATs, KQ)
        rs = sorted(
            [ranks.index(x.upper()) for x in token[:2]],
            reverse=True
        )
        normalized = ''.join(ranks[i] for i in rs) + token_suitedness(token)
    return normalized


def token_suitedness(ht):
    """Determine the suitedness of a handtype token.
        s=suited, o=offsuit, p=pair, n=not specified
    """
    if len(ht) == 3:
        if ht[0] == ht[1]:
            raise RangeStringError("Pairs cannot have suitedness")
        return ht[-1]
    elif ht[0] == ht[1]:
        return 'p'
    else:
        return 'n'


def token_to_hands(ht):
    """Take a single handtype token and return a list of possible hand string
    tuples. e.g.:
        ATs -> [("Ac", "Tc"), ("Ad", "Td"), ("Ah", "Th"), ("As", "Ts")]
    """
    hands = []
    if len(ht) == 4:
        hands.append((ht[:2], ht[2:]))
    else:
        suitedness = token_suitedness(ht)
        for suit_1 in suits:
            if suitedness == 's':
                other_suits = (suit_1, )
            elif suitedness == 'o':
                other_suits = [x for x in suits if not x == suit_1]
            elif suitedness == 'p':
                other_suits = suits[suits.index(suit_1)+1:]
            for suit_2 in other_suits:
                hand = (ht[0] + suit_1, ht[1] + suit_2)
                if suitedness == 'p':
                    hand = tuple(reversed(hand))
                hands.append(hand)
    return hands


class RangeStringError(Exception):
    pass


parser = make_parser()
