#!/bin/sh

cd /eval7
for PYTHON in 'python3.7' 'python3.8'; do
  VENV="/venv-$(basename "$PYTHON")"
  . "$VENV/bin/activate"
  rm dist/*.whl
  python setup.py bdist_wheel
  auditwheel repair dist/*.whl
  deactivate
done
