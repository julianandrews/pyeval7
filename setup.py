from setuptools import setup
from Cython.Build import cythonize

extensions = cythonize('eval7/*.pyx')

setup(
    name='eval7',
    version='0.1.2',
    description='A poker hand evaluation and equity calculation library',
    url='https://github.com/JulianAndrews/pyeval7',
    license='MIT',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Cython',
        'Topic :: Software Development :: Libraries',
        'Topic :: Games/Entertainment',
    ],
    keywords='poker equity library',
    packages=['eval7'],
    ext_modules=extensions,
    install_requires=['pyparsing', 'future'],
)
