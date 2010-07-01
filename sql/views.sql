
create view public.joini_constraints as
select 
	table_fks.t_fk_oid,
 	pgc_pk.relname as t_fk_table,
 	table_fks.t_fk_columns,
 	table_fks.t_pk_oid,
 	pgc_fk.relname as t_pk_table,
 	table_fks.t_pk_columns,
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
			) as fk_columns

		) as t_fk_columns,
    (
    	select array(
				select 
					pga.attname
				from
					generate_series(array_lower(pgcn.confkey,1), array_upper(pgcn.confkey,1)) as gs
					join pg_catalog.pg_attribute pga on pga.attrelid = pgcn.confrelid and pga.attnum = pgcn.confkey[gs]
			) as pk_columns

		) as t_pk_columns
	from 
		pg_catalog.pg_class pgc
    join pg_catalog.pg_constraint pgcn on pgcn.conrelid = pgc.oid
    join pg_catalog.pg_namespace pgn ON pgn.oid = pgc.relnamespace
  where  pgcn.contype='f'
) as table_fks
join pg_catalog.pg_class pgc_pk on pgc_pk.oid = table_fks.t_pk_oid
join pg_catalog.pg_class pgc_fk on pgc_fk.oid = table_fks.t_fk_oid;
grant all on public.joini_constraints to public;
