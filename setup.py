from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

setup(
    name = "Eval7",
    version = "0.1",
    description = "Poker Evaluator and Equity Calculator",
    packages = ['eval7'],
    ext_modules = cythonize('eval7/*.pyx'),
    install_requires = ['cython', 'pyparsing'],
)

