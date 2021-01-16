from os import path
from setuptools import setup
from Cython.Build import cythonize

this_directory = path.abspath(path.dirname(__file__))
with open(path.join(this_directory, 'README.rst'), encoding='utf-8') as f:
    long_description = f.read()

extensions = cythonize('eval7/*.pyx')

setup(
    name='eval7',
    version='0.1.9',
    description='A poker hand evaluation and equity calculation library',
    long_description=long_description,
    long_description_content_type='text/x-rst',
    url='https://github.com/JulianAndrews/pyeval7',
    license='MIT',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Cython',
        'Topic :: Software Development :: Libraries',
        'Topic :: Games/Entertainment',
    ],
    keywords='poker equity library',
    packages=['eval7'],
    ext_modules=extensions,
    install_requires=['pyparsing', 'future'],
)
