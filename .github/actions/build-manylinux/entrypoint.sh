#!/bin/sh

set -e -u -x

for PYBIN in /opt/python/cp3*/bin; do
  "${PYBIN}/pip" install cython
  "${PYBIN}/pip" wheel . -w unfixed-wheels
done

for wheel in unfixed-wheels/*.whl; do
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" -w wheelhouse/
    fi
done
