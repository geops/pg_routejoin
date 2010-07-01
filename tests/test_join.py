import unittest
from pg_routejoin.join import *

class TestJoin(unittest.TestCase):

  def test_joininset(self):
    j1 = Join("t1", "t2", "s1", "s2", ("c1_1", "c1_2"), ("c2_1", "c2_2"))
    j2 = LeftJoin("t2", "t1", "s2", "s1", ("c2_1", "c2_2"), ("c1_1", "c1_2"))
    
    s1 = set()
    s1.add(j1)
    s1.add(j2)
    self.assertTrue(len(s1) == 1, "hashing problem: there should only be one join in the set")
    
    j3 = Join("t3", "t2", "s3", "s2", ("c3_1", "c3_2"), ("c2_1", "c2_2"))

    s2 = set()
    s2.add(j1)
    s2.add(j3)
    self.assertTrue(len(s2) == 2, "hashing problem: there should be two joins in the set")
