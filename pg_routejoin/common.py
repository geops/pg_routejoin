
class PathError(Exception):
  """
  parent class for all routing related errors
  """
  pass


class MissingNodeError(Exception):
  """
  a referenced node is missing in the graph
  """
  def __init__(self, node):
    self.node = node

  def __str__(self):
    return "Node %d in not in the graph" % self.node


class NotEnoughNodesError(Exception):
  def __str__(self):
    return "need at least two nodes to join someting"


class RoutingError(Exception):
  """
  there is no connection between to nodes
  """
  def __init__(self, node_start, node_end):
    self.node_start = node_start
    self.node_end = node_end

  def __str__(self):
    return "No connection between node %d and node %d" % (self.node_start, self.node_end)


