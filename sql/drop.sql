begin;

drop view if exists public.routejoin_routes;
drop table if exists public.routejoin_userdefined;
drop view if exists public.routejoin_constraints;
drop function if exists public.routejoin_vizz(oid[]);
drop function if exists public.routejoin_route(oid[]);

commit;
