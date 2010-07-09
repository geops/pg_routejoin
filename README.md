What it is...
=============

This project offers database functions to dynamically create
the SQL to join a list of tables and views.

The joins are generated based on constraints (foreign keys) as
defined in the database and are routed using [Dijkstra's algorithm](http://en.wikipedia.org/wiki/Dijkstra's_algorithm).
Additional routes can be defined or others can be ignored, 
for example for including views in the joins.


Documentation
=============

See the comments of functions and views in the 
database.


Requirements
============

* Postgresql 8.3+ (maybe some lower versions will also work)
* plpythonu database language
* Python 2.5+


Installation
============

* install the Python module with

  ``./setup.py install``

* create the plpythonu database language in your database

  ``create language plpythonu;``

* import the sql/create.sql file in the database
