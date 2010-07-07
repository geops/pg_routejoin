from routejoin.route import route_network
import StringIO


def route_vizz(G, nodes=[]):
  """
  create a graphvizz dot file form a routing

  takes same parameters as route_network
  returns a string with the contents of the dot file
  """
  sio = StringIO.StringIO()

  netw = route_network(G, nodes)

  sio.write("graph route {\n")

  connection_nodes = []
  for route in netw:
    for node in route:
      if node not in connection_nodes and node not in nodes:
        connection_nodes.append(node)

  # highliht the target nodes in blue
  for node in nodes:
    sio.write("  \"%d\" [color = \"blue\"];\n" % node)

  # the connection nodes are colored red
  for node in connection_nodes:
    sio.write("  \"%d\" [color = \"red\"];\n" % node)

  included_nodes = connection_nodes + nodes
  
  # collect all existing connection from the graph
  all_connections = []
  for node, neighbor_dict in G.iteritems():
    for neighbor in neighbor_dict.iterkeys():
      if (neighbor, node) not in all_connections:
        all_connections.append((node, neighbor))

  for row in all_connections:
    formating = ""
    # draw routed connections in red
    if row[0] in included_nodes and row[1] in included_nodes:
      formating="[color=\"red\"]"

    sio.write("  \"%d\" -- \"%d\" %s;\n" % (row[0], row[1], formating))
  sio.write("}\n")
  return sio.getvalue()



