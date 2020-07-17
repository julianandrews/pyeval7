#!/bin/sh

for PYTHON in 'python3.7' 'python3.8'; do
  VENV="/venv-$(basename "$PYTHON")"
  python -m virtualenv -p "$PYTHON" "$VENV"
  . "${VENV}/bin/activate"
  pip install auditwheel cython
  deactivate
done
