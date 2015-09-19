eval7
=====

Python Texas Hold'em hand evaluation library based on Anonymous7's codebase
which is in turn based on Keith Rule's hand evaluator (which you can see
here_). The library also provides a parser for an extended set of PokerStove
style range strings, and a more or less working equity calculator, though
that still needs a little cleaning up.

.. _here: http://www.codeproject.com/Articles/12279/Fast-Texas-Holdem-Hand-
          Evaluation-and-Analysis

The library is fairly basic at the moment; only the functionality needed by
`Flop Ferret`_ has been fully implemented. Time permitting, the goal is to
provide a fully featured poker hand evaluator and range equity calculator
with a clean native python interface and all performance critical parts
implemented in Cython.

.. _Flop Ferret: https://github.com/JulianAndrews/FlopFerret

Installation
------------

eval7 requires python 2.6+. The build process requires cython (tested with
0.23). If you have a working copy of python::

    pip install cython

should work on most platforms. Installing via your package manager or from
source should also work.

Simple Installation::

    pip install eval7

Usage
-----

Basic usage::

    >>> import eval7
    >>> from pprint import pprint
    >>> deck = eval7.Deck()
    >>> deck.shuffle()
    >>> hand = deck.deal(7)
    >>> pprint.pprint(hand)
    [Card("5c"),
     Card("9s"),
     Card("8d"),
     Card("5d"),
     Card("Ac"),
     Card("Qc"),
     Card("3d")]
    >>> eval7.evaluate(hand)
    17025648

    >>> hand = [eval7.Card(s) for s in ('As', '2c', '3d', '5s', '4c')]
    >>> eval7.evaluate(hand)
    67305472

Larger numbers represent better hands!

``Card`` objects provide a convenient python interface to cards with ``rank``
and ``suit`` attributes.

``Deck`` object provide some basic functionality that might be useful for
simple simulations such as ``sample``, ``shuffle``, and ``deal``. The deck
code isn't very well optimized at this point, so while it works well for
quick lightweight simulations, you're not going to get the performance
out of it needed for precise range vs. range equity calculations.

Hand Ranges
-----------

eval7 also provides a parser for weighted PokerStove style hand ranges.

Examples::

    >>> from pprint import pprint
    >>> hr = eval7.HandRange("AQs+, 0.4(AsKs)")
    >>> pprint(hr.hands)
    [((Card("Ac"), Card("Qc")), 1.0),
     ((Card("Ad"), Card("Qd")), 1.0),
     ((Card("Ah"), Card("Qh")), 1.0),
     ((Card("As"), Card("Qs")), 1.0),
     ((Card("Ac"), Card("Kc")), 1.0),
     ((Card("Ad"), Card("Kd")), 1.0),
     ((Card("Ah"), Card("Kh")), 1.0),
     ((Card("As"), Card("Ks")), 1.0),
     ((Card("As"), Card("Ks")), 0.4)]

    >>> hr = eval7.HandRange("AJ+, ATs, KQ+, 33-JJ, 0.8(QQ+, KJs)")
    >>> len(hr)
    144

At present the HandRange objects are just a thin front-end for the
range-string parser. Ultimately the hope is to add Cython backed sampling,
enumeration, and HandRange vs. HandRange equity calculation.
