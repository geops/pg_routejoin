from routejoin.common import *
import heapq


def shortest_path(G, start, end):
    """
    djikstras routing algorythm

    adapted from Connelly Barnes version
    http://barnesc.blogspot.com/2005/10/modified-dijkstras-algorithm-in-python.html
    (released in the public domain)
    """
    def flatten(L):       # Flatten linked list of form [0,[1,[2,[]]]]
        while len(L) > 0:
            yield L[0]
            L = L[1]

    q = [(0, start, ())]  # Heap of (cost, path_head, path_rest).
    visited = set()       # Visited vertices.
    while True:
        try:
            (cost, v1, path) = heapq.heappop(q)
        except IndexError:
            raise RoutingError(start, end)

        if v1 not in visited:
            visited.add(v1)
            if v1 == end:
                return list(flatten(path))[::-1] + [v1]
            path = (v1, path)
            if not v1 in G:
                raise MissingNodeError(v1)
            else:
                for (v2, cost2) in G[v1].iteritems():
                    if v2 not in visited:
                        heapq.heappush(q, (cost + cost2, v2, path))
