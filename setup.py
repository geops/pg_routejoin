#!/usr/bin/env python

from distutils.core import setup, Extension, Command
from unittest import TextTestRunner, TestLoader
from routejoin import __version__ as versionstring

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


setup(name="routejoin",
  version=versionstring,
  license="MIT",
  packages=['routejoin'],
  cmdclass = {"test": TestCommand})

