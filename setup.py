from setuptools import setup

try:
    from Cython.Build import cythonize
except ImportError:
    from distutils.extension import Extension
    extensions = [Extension(name, ['eval7/%s.c' % name])
                  for name in ('wh_rand', 'cards', 'equity', 'eval7')]
else:
    extensions = cythonize('eval7/*.pyx')

setup(
    name='Eval7',
    version='0.1.1',
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
    install_requires=['pyparsing'],
)
