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
select rc.*, 100::integer as routing_cost, False as left_join 
from public.routejoin_constraints rc
left join public.routejoin_userdefined ru on
  ru.t_pk_schema = rc.t_pk_schema and
  ru.t_pk_table = rc.t_pk_table and
  ru.t_pk_columns = rc.t_pk_columns and
  ru.t_fk_schema = rc.t_fk_schema and
  ru.t_fk_table = rc.t_fk_table and
  ru.t_fk_columns = rc.t_fk_columns
where ru.action is null or ru.action = 'add'
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
  NULL::name as conname,
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
from pg_routejoin import vizz

if type(table_oids_in) == str:
  # at this point plpython does not seem to have native array support
  table_oids = map(int, table_oids_in.strip("{}").split(","))
else:
  # convert the table_oids to int
  table_oids = map(int, table_oids_in)

# get the list of routes
q_routes = plpy.prepare(
  """select * from public.routejoin_routes;""")
defined_routes = plpy.execute(q_routes)

# build the graph 
G = {}
for row in defined_routes:
  t_fk_oid = int(row["t_fk_oid"])
  t_pk_oid = int(row["t_pk_oid"])
  if not G.has_key(t_fk_oid):
    G[t_fk_oid] = {}
  if not G.has_key(t_pk_oid):
    G[t_pk_oid] = {}
  G[t_fk_oid][t_pk_oid] = row["routing_cost"]
  G[t_pk_oid][t_fk_oid] = row["routing_cost"]


try:
  return vizz.route_vizz(G, table_oids)
except Exception, e:
  plpy.error(str(e))

$$ language plpythonu;
alter function  public.routejoin_vizz(oid[]) owner to postgres;
grant all on function public.routejoin_vizz(oid[]) to public;



create or replace function public.routejoin_route(table_oids_in oid[]) 
returns text 
as $$
from pg_routejoin import route, join 
import StringIO


def sanitize_pg_array(pg_array):
  # only for one-dimesional arrays
  return map(str.strip, pg_array.strip("{}").split(","))

if type(table_oids_in) == str:
  # at this point plpython does not seem to have
  # native array parameter support
  table_oids = map(int, sanitize_pg_array(table_oids_in))
else:
  # convert the table_oids to int
  table_oids = map(int, table_oids_in)

# get the list of routes
q_routes = plpy.prepare(
  """select * from public.routejoin_routes;""")
defined_routes = plpy.execute(q_routes)

# build the graph 
G = {}
for row in defined_routes:
  t_fk_oid = int(row["t_fk_oid"])
  t_pk_oid = int(row["t_pk_oid"])
  if not G.has_key(t_fk_oid):
    G[t_fk_oid] = {}
  if not G.has_key(t_pk_oid):
    G[t_pk_oid] = {}
  G[t_fk_oid][t_pk_oid] = row["routing_cost"]
  G[t_pk_oid][t_fk_oid] = row["routing_cost"]


try:
  routes =  route.route_network(G, table_oids)

  # using a set would be nice, but a set reorders its contents
  joins = []
  included_nodes = []

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
              t_from_table  = row["t_pk_table"]
              t_from_schema = row["t_pk_schema"]
              t_from_columns = sanitize_pg_array(row["t_pk_columns"])
              t_to_table  = row["t_fk_table"]
              t_to_schema = row["t_fk_schema"]
              t_to_columns = sanitize_pg_array(row["t_fk_columns"])
            else:
              t_from_table  = row["t_fk_table"]
              t_from_schema = row["t_fk_schema"]
              t_from_columns = sanitize_pg_array(row["t_fk_columns"])
              t_to_table  = row["t_pk_table"]
              t_to_schema = row["t_pk_schema"]
              t_to_columns = sanitize_pg_array(row["t_pk_columns"])

            if row["left_join"]:
              this_join = join.LeftJoin(
                t_from_table,
                t_to_table,
                t_from_schema,
                t_to_schema,
                t_from_columns,
                t_to_columns)
            else:
              this_join = join.Join(
                t_from_table,
                t_to_table,
                t_from_schema,
                t_to_schema,
                t_from_columns,
                t_to_columns)

            if this_join not in joins:
              joins.append(this_join)
            break;

        last_node = next_node

  # build the join sql
  sql = StringIO.StringIO()
  if len(joins) > 0:
    sql.write(joins[0].toSql(is_first=True))
    for this_join in joins[1:]:
      sql.write("\n")
      sql.write(this_join.toSql())

  return sql.getvalue()

except Exception, e:
  plpy.error(str(e))

$$ language plpythonu;
alter function  public.routejoin_route(oid[]) owner to postgres;
grant all on function public.routejoin_route(oid[]) to public;


commit;


