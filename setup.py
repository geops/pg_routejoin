#!/usr/bin/env python

from distutils.core import setup, Extension, Command
from unittest import TextTestRunner, TestLoader

class TestCommand(Command):
  user_options = []
    
  def initialize_options(self):
    pass

  def finalize_options(self):
    pass

  def run(self):
    import tests
    loader = TestLoader()
    t = TextTestRunner()
    t.run(loader.loadTestsFromModule(tests))


setup(name="pg_routejoin",
  version="0.1",
  packages=['pg_routejoin'],
  cmdclass = {"test": TestCommand})

