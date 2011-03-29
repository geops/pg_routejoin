begin;


create view public.routejoin_constraints as
select 
	table_fks.t_pk_oid,
  pgns_pk.nspname as t_pk_schema,
 	pgc_pk.relname as t_pk_table,
 	table_fks.t_pk_columns,
 	table_fks.t_fk_oid,
  pgns_fk.nspname as t_fk_schema,
 	pgc_fk.relname as t_fk_table,
 	table_fks.t_fk_columns,
 	table_fks.conname

from
(
	select 
		pgc.oid as t_pk_oid,
    pgcn.confrelid as t_fk_oid,
    pgcn.conname, 
    (
    	select array(
				select 
					pga.attname
				from
					generate_series(array_lower(pgcn.conkey,1), array_upper(pgcn.conkey,1)) as gs
					join pg_catalog.pg_attribute pga on pga.attrelid = pgc.oid and pga.attnum = pgcn.conkey[gs]
			) as pk_columns

		) as t_pk_columns,
    (
    	select array(
				select 
					pga.attname
				from
					generate_series(array_lower(pgcn.confkey,1), array_upper(pgcn.confkey,1)) as gs
					join pg_catalog.pg_attribute pga on pga.attrelid = pgcn.confrelid and pga.attnum = pgcn.confkey[gs]
			) as fk_columns

		) as t_fk_columns
	from 
		pg_catalog.pg_class pgc
    join pg_catalog.pg_constraint pgcn on pgcn.conrelid = pgc.oid
    join pg_catalog.pg_namespace pgn ON pgn.oid = pgc.relnamespace
  where  pgcn.contype='f'
) as table_fks
join pg_catalog.pg_class pgc_pk on pgc_pk.oid = table_fks.t_pk_oid
join pg_catalog.pg_namespace pgns_pk on pgns_pk.oid = pgc_pk.relnamespace
join pg_catalog.pg_class pgc_fk on pgc_fk.oid = table_fks.t_fk_oid
join pg_catalog.pg_namespace pgns_fk on pgns_fk.oid = pgc_fk.relnamespace;
grant select on public.routejoin_constraints to public;
comment on view public.routejoin_constraints is '
these routes are derivated from foreignkey constraints.

to overrride/ingore some of these routes see the table
public.routejoin_userdefined.
';

create table public.routejoin_userdefined (
  ru_id serial primary key,
  t_pk_schema name,
  t_pk_table name,
  t_pk_columns name[],
  t_fk_schema name,
  t_fk_table name,
  t_fk_columns name[],
  left_join boolean default false,
  routing_cost integer default 100 check (routing_cost>0),
  action character varying default 'add' check (action in ('add', 'ignore'))
);
comment on table public.routejoin_userdefined is '
this table allows the definition of additional routes, for example for
views, and ignoring of existing routes from  public.routejoin_constraints.

The routes are matched against public.routejoin_constraints using all of
the t_* columns. the order whether a table is in t_pk or t_fk matters.

The "action" column defines if the route is added or ignore. See the check
constraint for possible values.

"routing_cost" allows teaking the routers preference for this route. The lower
the value is, the more prefered to route is. The default value is 100, the minimum
0. The router tries to reuse existing joins.

Column "left_join" - when true, a LEFT JOIN is used.';
grant select on public.routejoin_userdefined to public;


create or replace view public.routejoin_routes as
select 
  rc.t_pk_oid, 
  rc.t_pk_table,
  rc.t_pk_schema,
  rc.t_pk_columns,
  rc.t_fk_oid,
  rc.t_fk_table,
  rc.t_fk_schema,
  rc.t_fk_columns,
  100::integer as routing_cost, 
  False as left_join 
from public.routejoin_constraints rc
left join public.routejoin_userdefined ru on
  ru.t_pk_schema = rc.t_pk_schema and
  ru.t_pk_table = rc.t_pk_table and
  ru.t_pk_columns = rc.t_pk_columns and
  ru.t_fk_schema = rc.t_fk_schema and
  ru.t_fk_table = rc.t_fk_table and
  ru.t_fk_columns = rc.t_fk_columns
where ru.action is null
except
select 
  pcpk.oid as t_pk_oid,
  ru.t_pk_table,
  ru.t_pk_schema,
  ru.t_pk_columns,
  pcfk.oid as t_fk_oid,
  ru.t_fk_table,
  ru.t_fk_schema,
  ru.t_fk_columns,
  ru.routing_cost,
  ru.left_join
from public.routejoin_userdefined ru
join pg_catalog.pg_class pcpk on pcpk.relname = ru.t_pk_table
join pg_catalog.pg_namespace pnpk on pcpk.relnamespace=pnpk.oid and pnpk.nspname=ru.t_pk_schema
join pg_catalog.pg_class pcfk on pcfk.relname = ru.t_fk_table
join pg_catalog.pg_namespace pfpk on pcfk.relnamespace=pfpk.oid and pfpk.nspname=ru.t_fk_schema
where ru.action = 'ignore'
except
select --  switch the positions of "from" an "to" table
  pcfk.oid as t_pk_oid,
  ru.t_fk_table as t_pk_table,
  ru.t_fk_schema as t_pk_schema,
  ru.t_fk_columns as t_pk_columns,
  pcpk.oid as t_fk_oid,
  ru.t_pk_table as t_fk_table,
  ru.t_pk_schema as t_fk_schema,
  ru.t_pk_columns as t_fk_columns,
  ru.routing_cost,
  ru.left_join
from public.routejoin_userdefined ru
join pg_catalog.pg_class pcpk on pcpk.relname = ru.t_pk_table
join pg_catalog.pg_namespace pnpk on pcpk.relnamespace=pnpk.oid and pnpk.nspname=ru.t_pk_schema
join pg_catalog.pg_class pcfk on pcfk.relname = ru.t_fk_table
join pg_catalog.pg_namespace pfpk on pcfk.relnamespace=pfpk.oid and pfpk.nspname=ru.t_fk_schema
where ru.action = 'ignore'
union 
select 
  pcpk.oid as t_pk_oid,
  ru.t_pk_table,
  ru.t_pk_schema,
  ru.t_pk_columns,
  pcfk.oid as t_fk_oid,
  ru.t_fk_table,
  ru.t_fk_schema,
  ru.t_fk_columns,
  ru.routing_cost,
  ru.left_join
from public.routejoin_userdefined ru
join pg_catalog.pg_class pcpk on pcpk.relname = ru.t_pk_table
join pg_catalog.pg_namespace pnpk on pcpk.relnamespace=pnpk.oid and pnpk.nspname=ru.t_pk_schema
join pg_catalog.pg_class pcfk on pcfk.relname = ru.t_fk_table
join pg_catalog.pg_namespace pfpk on pcfk.relnamespace=pfpk.oid and pfpk.nspname=ru.t_fk_schema
where ru.action = 'add';
comment on view public.routejoin_routes is '
this view contains the combined routes from public.routejoin_constraints 
and public.routejoin_userdefined, which get used by the routing functions.';
grant select on public.routejoin_routes to public;


create or replace view public.routejoin_oidlookup as
select distinct
  t_pk_oid as oid,
  t_pk_table as "table",
  t_pk_schema as "schema"
from public.routejoin_routes 
union
select 
  t_fk_oid as oid,
  t_fk_table as "table",
  t_fk_schema as "schema"
from public.routejoin_routes;
grant select on public.routejoin_oidlookup to public;


create or replace function public.routejoin_vizz(table_oids_in oid[]) 
returns text 
as $$
from routejoin import vizz, postgres, graph

if type(table_oids_in) == str:
  # at this point plpython does not seem to have
  # native array parameter support
  table_oids = map(int, postgres.sanitize_pg_array(table_oids_in))
else:
  # convert the table_oids to int
  table_oids = map(int, table_oids_in)


# get the list of routes
q_routes = plpy.prepare(
  """select * from public.routejoin_routes;""")
defined_routes = plpy.execute(q_routes)

# build the graph 
G = graph.build_graph(defined_routes)

try:
  return vizz.route_vizz(G, table_oids)
except Exception, e:
  plpy.error(str(e))

$$ language plpythonu;
alter function  public.routejoin_vizz(oid[]) owner to postgres;
grant execute on function public.routejoin_vizz(oid[]) to public;



create or replace function public.routejoin_route(table_oids_in oid[]) 
returns text 
as $$
from routejoin import route, table, postgres, graph 
import StringIO

if type(table_oids_in) == str:
  # at this point plpython does not seem to have
  # native array parameter support
  table_oids = map(int, postgres.sanitize_pg_array(table_oids_in))
else:
  # convert the table_oids to int
  table_oids = map(int, table_oids_in)

# get the list of routes
q_routes = plpy.prepare(
  """select * from public.routejoin_routes;""")
defined_routes = plpy.execute(q_routes)

# build the graph 
G = graph.build_graph(defined_routes)

try:
  routes =  route.route_network(G, table_oids)

  # using a set would be nice, but a set reorders its contents
  joins = []
  tables = []

  for route in routes:
    if len(route)>1: # should always be the case

      last_node = route[0]
      for next_node in route[1:]:
        # find tables in the defined_routes
        for row in defined_routes:
          t_pk_oid = int(row["t_pk_oid"])
          t_fk_oid = int(row["t_fk_oid"])
          if ((t_pk_oid == last_node and t_fk_oid == next_node) or
            (t_pk_oid == next_node and t_fk_oid == last_node)):

            # keep the order of the tables in the join
            if last_node == t_pk_oid:
              t_from_table  = table.Table(row["t_pk_table"], row["t_pk_schema"])
              t_from_columns = postgres.sanitize_pg_array(row["t_pk_columns"])
              t_to_table  = table.Table(row["t_fk_table"], row["t_fk_schema"])
              t_to_columns = postgres.sanitize_pg_array(row["t_fk_columns"])
            else:
              t_from_table  = table.Table(row["t_fk_table"], row["t_fk_schema"])
              t_from_columns = postgres.sanitize_pg_array(row["t_fk_columns"])
              t_to_table  = table.Table(row["t_pk_table"], row["t_pk_schema"])
              t_to_columns = postgres.sanitize_pg_array(row["t_pk_columns"])

            try:
              from_table_pos = tables.index(t_from_table)
            except ValueError:
              tables.append(t_from_table)
              from_table_pos = len(tables)-1

            try:
              to_table_pos = tables.index(t_to_table)
            except ValueError:
              tables.append(t_to_table)
              to_table_pos = len(tables)-1

            # build join condition
            to_cols = tables[to_table_pos].prepend_alias(t_to_columns)
            from_cols = tables[from_table_pos].prepend_alias(t_from_columns)

            # always add the conditions to the last table, to avoid
            # joins without conditions
            tables[max(from_table_pos,to_table_pos)].add_join(to_cols, from_cols)

            # set the join type,
            if row["left_join"] == True and tables[max(from_table_pos,to_table_pos)].jointype != "join": 
              # left joins are only set if there is not already a normal join
              tables[max(from_table_pos,to_table_pos)].jointype = "left join"
            else:
              tables[max(from_table_pos,to_table_pos)].jointype = "join"

            break;

        last_node = next_node

  # build the join sql
  sql = StringIO.StringIO()
  if len(tables) > 0:
    # print first table
    sql.write(tables[0].fullname)
    sql.write("\n")
    for table in tables[1:]:
      sql.write(table.joinsql)
      sql.write("\n")

  return sql.getvalue()

except Exception, e:
  plpy.error(str(e))

$$ language plpythonu;
alter function  public.routejoin_route(oid[]) owner to postgres;
grant execute on function public.routejoin_route(oid[]) to public;


create or replace function public.routejoin_route_left(table_oids_in oid[]) 
returns text 
as $$
from routejoin import route, table, postgres, graph 
import StringIO

if type(table_oids_in) == str:
  # at this point plpython does not seem to have
  # native array parameter support
  table_oids = map(int, postgres.sanitize_pg_array(table_oids_in))
else:
  # convert the table_oids to int
  table_oids = map(int, table_oids_in)

# get the list of routes
q_routes = plpy.prepare(
  """select * from public.routejoin_routes;""")
defined_routes = plpy.execute(q_routes)

# build the graph 
G = graph.build_graph(defined_routes)

try:
  routes =  route.route_network(G, table_oids)

  # using a set would be nice, but a set reorders its contents
  joins = []
  tables = []

  for route in routes:
    if len(route)>1: # should always be the case

      last_node = route[0]
      for next_node in route[1:]:
        # find tables in the defined_routes
        for row in defined_routes:
          t_pk_oid = int(row["t_pk_oid"])
          t_fk_oid = int(row["t_fk_oid"])
          if ((t_pk_oid == last_node and t_fk_oid == next_node) or
            (t_pk_oid == next_node and t_fk_oid == last_node)):

            # keep the order of the tables in the join
            if last_node == t_pk_oid:
              t_from_table  = table.Table(row["t_pk_table"], row["t_pk_schema"])
              t_from_columns = postgres.sanitize_pg_array(row["t_pk_columns"])
              t_to_table  = table.Table(row["t_fk_table"], row["t_fk_schema"])
              t_to_columns = postgres.sanitize_pg_array(row["t_fk_columns"])
            else:
              # always start from the first node of a route
              if last_node != route[0]:
                t_to_table  = table.Table(row["t_fk_table"], row["t_fk_schema"])
                t_to_columns = postgres.sanitize_pg_array(row["t_fk_columns"])
                t_from_table  = table.Table(row["t_pk_table"], row["t_pk_schema"])
                t_from_columns = postgres.sanitize_pg_array(row["t_pk_columns"])
              else:
                t_from_table  = table.Table(row["t_fk_table"], row["t_fk_schema"])
                t_from_columns = postgres.sanitize_pg_array(row["t_fk_columns"])
                t_to_table  = table.Table(row["t_pk_table"], row["t_pk_schema"])
                t_to_columns = postgres.sanitize_pg_array(row["t_pk_columns"])

            try:
              from_table_pos = tables.index(t_from_table)
            except ValueError:
              tables.append(t_from_table)
              from_table_pos = len(tables)-1

            try:
              to_table_pos = tables.index(t_to_table)
            except ValueError:
              tables.append(t_to_table)
              to_table_pos = len(tables)-1

            # build join condition
            to_cols = tables[to_table_pos].prepend_alias(t_to_columns)
            from_cols = tables[from_table_pos].prepend_alias(t_from_columns)

            # always add the conditions to the last table, to avoid
            # joins without conditions
            tables[max(from_table_pos,to_table_pos)].add_join(to_cols, from_cols)

            # set the join type,
            tables[max(from_table_pos,to_table_pos)].jointype = "left join"

            break;

        last_node = next_node

  # build the join sql
  sql = StringIO.StringIO()
  if len(tables) > 0:
    # print first table
    sql.write(tables[0].fullname)
    sql.write("\n")
    for table in tables[1:]:
      sql.write(table.joinsql)
      sql.write("\n")

  return sql.getvalue()

except Exception, e:
  plpy.error(str(e))

$$ language plpythonu;
alter function  public.routejoin_route_left(oid[]) owner to postgres;
grant execute on function public.routejoin_route_left(oid[]) to public;
comment on function  public.routejoin_route_left(oid[]) is '
this function ignores the joint types specified in public.routejoin_routes
and uses only left joins instead.

The first table/view of the oid array is used as the "from" table, all
the others are joined to it.

This is probably useful for search queries when looking rows matching a
criteria without loosing records without data in any of the joined tables.
';



create or replace function public.routejoin_version() 
returns text 
as $$
from routejoin import __version__

return __version__
$$ language plpythonu;
alter function  public.routejoin_version() owner to postgres;
grant execute on function public.routejoin_version() to public;


commit;


