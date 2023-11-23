-- Thurs, Nov 2, 2023
-- Use Fruman et al. (2017) 10.1016/j.cell.2017.07.029. as seed
-- Extract references from Scopus. Perform manual cleaning to handle "" and NAs mostly.
-- Load into chackoge.fruman_cleaned table.
-- Import fruman_cleaned using DataGrip
-- In DataGrip set primary key to eid /* Uncomment lower two lines for single execution */

-- Force lower case on fruman dois
UPDATE chackoge.fruman_cleaned SET doi=lower(doi);
-- Set doi = 'none' instead of empty string
UPDATE chackoge.fruman_cleaned SET doi='none' where doi ='';

select count(1) from fruman_cleaned;
select count(distinct doi) from fruman_cleaned;
select count(distinct pub_med_id) from fruman_cleaned;

-- fruman_cleaned has 283 distinct dois and 274 distinct pmids

-- collect all nodes (as iids) that cite dois in fruman_cleaned
-- iid is integer_id from open_citations_2023 table

DROP TABLE IF  EXISTS public.pi3k_nl;
-- Stage 1 Citing
DROP TABLE IF EXISTS pi3k_nl;
CREATE TABLE public.pi3k_nl AS
SELECT DISTINCT oc2e.citing_iid as iid
FROM open_citations_2023_edgelist oc2e
INNER JOIN chackoge.fruman_cleaned fc
ON oc2e.cited=fc.doi;

-- Stage 1 Cited
INSERT INTO public.pi3k_nl (iid)
SELECT oc2e.cited_iid
FROM open_citations_2023_edgelist oc2e
INNER JOIN chackoge.fruman_cleaned fc
ON oc2e.citing=fc.doi;

-- Stage 1 Seed refs
INSERT INTO public.pi3k_nl (iid)
SELECT ocp.iid FROM open_citation_pubs ocp
INNER JOIN fruman_cleaned fc
ON fc.doi=ocp.doi;

-- De-duplicate
DROP TABLE IF EXISTS temp;
CREATE TABLE public.temp AS
SELECT DISTINCT iid FROM pi3k_nl;
SELECT COUNT(1) from temp;

TRUNCATE public.pi3k_nl;
INSERT INTO public.pi3k_nl
SELECT iid from temp;
CREATE INDEX pi3k_nl_idx ON pi3k_nl(iid);
DROP TABLE temp;
SELECT COUNT(1) FROM pi3k_nl;

-- Stage II nodes that cite Stage I in pi3k_nl
INSERT INTO pi3k_nl(iid)
SELECT DISTINCT oc2e.citing_iid FROM open_citations_2023_edgelist oc2e
INNER JOIN pi3k_nl pn
ON pn.iid=oc2e.cited_iid;

-- Stage II nodes that are cited by Stage I in pi3k_nl
INSERT INTO pi3k_nl(iid)
SELECT DISTINCT oc2e.cited_iid FROM open_citations_2023_edgelist oc2e
INNER JOIN pi3k_nl pn
ON pn.iid=oc2e.citing_iid;

-- de-duplicate
CREATE TABLE public.temp AS
SELECT DISTINCT iid FROM pi3k_nl;
SELECT COUNT(1) from temp;

TRUNCATE public.pi3k_nl;
INSERT INTO public.pi3k_nl
SELECT iid from temp;
DROP TABLE temp;

SELECT COUNT(1) FROM pi3k_nl;
DROP INDEX pi3k_nl_idx;
ALTER TABLE pi3k_nl ADD PRIMARY KEY (iid);

-- CREATE EDGELIST
CREATE TABLE public.pi3k_el AS
SELECT citing_iid,cited_iid from open_citations_2023_edgelist oc2e
INNER JOIN pi3k_nl p1
ON p1.iid=oc2e.citing_iid
INNER JOIN pi3k_nl p2
ON p2.iid=oc2e.cited_iid;

-- CREATE EDGELIST for comparison using subquery
DROP TABLE IF EXISTS pi3k_el2;
CREATE TABLE pi3k_el2 AS
SELECT citing_iid,cited_iid from open_citations_2023_edgelist oc2e
WHERE citing_iid in (SELECT iid FROM pi3k_nl) AND
cited_iid in (SELECT iid FROM pi3k_nl);

SELECT COUNT(1) from pi3k_el; -- 427496813
SELECT COUNT(1) FROM pi3k_el2 -- 427496813

-- Create pmid-restricted network
-- Load output of parse_pmd.R copied over from valhalla as a csv.


