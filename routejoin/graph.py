
def build_graph(defined_routes):
  """
  build the graph form route definitions
  """
  G={}
  for row in defined_routes:
    t_fk_oid = int(row["t_fk_oid"])
    t_pk_oid = int(row["t_pk_oid"])
    if not G.has_key(t_fk_oid):
      G[t_fk_oid] = {}
    if not G.has_key(t_pk_oid):
      G[t_pk_oid] = {}
    G[t_fk_oid][t_pk_oid] = row["routing_cost"]
    G[t_pk_oid][t_fk_oid] = row["routing_cost"]
  return G
