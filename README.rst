eval7
=====

.. image:: https://github.com/julianandrews/pyeval7/workflows/Tests/badge.svg
    :target: https://github.com/julianandrews/pyeval7/actions

Python Texas Hold'em hand evaluation library based on Anonymous7's codebase
which is in turn based on Keith Rule's hand evaluator (which you can see
here_). Eval7 also provides a parser for an extended set of PokerStove
style range strings, and approximate equity calculation for unweighted ranges.

.. _here: http://www.codeproject.com/Articles/12279/Fast-Texas-Holdem-Hand-
          Evaluation-and-Analysis

Eval7 is a work in progress: only the functionality needed by `Flop Ferret`_
has been fully implemented. Time permitting, the goal is to provide a fully
featured poker hand evaluator and range equity calculator with a clean native
python interface and all performance critical parts implemented in Cython.

.. _Flop Ferret: https://github.com/JulianAndrews/FlopFerret

Installation
------------

Pip Installation
~~~~~~~~~~~~~~~~

Check PyPI_ to see if there are recent binary `.whl` packages for your version
of python. If there are, you can just install with::

   pip install eval7

If there isn't a wheel for your package, feel free to open an issue on GitHub.

.. _PyPI: https://pypi.org/project/eval7/#files

Other Platforms
~~~~~~~~~~~~~~~

eval7 is tested on python 3.5, 3.6, 3.7 and 3.8 and likely works with 2.7+.
The build process requires cython. If you have a working copy of pip::

    pip install cython

should work on many platforms. Once you have cython, clone the repo and install
with::

    python setup.py install

Usage
-----

Basic usage::

    >>> import eval7, pprint
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
    >>> eval7.handtype(17025648)
    'Pair'

    >>> hand = [eval7.Card(s) for s in ('As', '2c', '3d', '5s', '4c')]
    >>> eval7.evaluate(hand)
    67305472
    >>> eval7.handtype(67305472)
    'Straight'

``Deck`` objects provide ``sample``, ``shuffle``, ``deal`` and ``peek``
methods. The deck code is currently implemented in pure python and works well
for quick lightweight simulations, but is too slow for full range vs. range
equity calculations. Ideally this code will be rewritten in Cython.

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

Equity
------

eval7 also provides equity calculation functions: ``py_hand_vs_range_exact``,
``py_hand_vs_range_monte_carlo`` and ``py_all_hands_vs_range``. These don't yet
support weighted ranges and could probably benefit from optimization.  See
``equity.pyx`` for documentaiton.
