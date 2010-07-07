What it is...
=============

This projects offers database functions to dynamicly create
the SQL to join a list of tables and views.

Theses joins are generated based on the constraints (foreignkeys)
defined in the database and are routed using [Dijkstra's algorithm](http://en.wikipedia.org/wiki/Dijkstra's_algorithm).
Optionaly additional routes can be defined or ignored, for example
for including views in the joins.


Documentation
=============

See the comments of the functions and views in the 
database.


Requirements
============

* Postgresql 8.3+ (maybe some lower versions will also work)
* plpythonu database language
* Python 2.5+


Installation
============

* install the Python module with
  ./setup.py install

* create the plpythonu database language in your database
  create language plpythonu

* import the sql/create.sql file in the database
