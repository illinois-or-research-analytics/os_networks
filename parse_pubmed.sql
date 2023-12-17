-- process pmids and dois parsed from PubMed using parse_pmd.R
-- load pmid_doi.csv into the public.pmid_doi_parsed table

-- Dec 12, 2023 loaded new data that includes revised date field. This is treated as an integer.
-- remove null PMID rows
TRUNCATE public.pmid_doi_parsed;
COPY public.pmid_doi_parsed FROM '/data1/chackoge/pmid_doi.csv' WITH(FORMAT CSV, HEADER);
SELECT COUNT(1) from public.pmid_doi_parsed; --34960645

-- remove all rows with null pmids; usually these are blank lines.
DELETE from public.pmid_doi_parsed WHERE pmid IS NULL; --34960645

--eliminate all pmids where doi_articleid is null or empty string
DELETE FROM public.pmid_doi_parsed where doi_articleid is null;
DELETE FROM public.pmid_doi_parsed where doi_articleid = '';
SELECT COUNT(1) from public.pmid_doi_parsed;--26135266
SELECT COUNT(DISTINCT pmid) FROM public.pmid_doi_parsed; --26131748

-- force lower case on all dois to facilitate joining with Open Citations
UPDATE public.pmid_doi_parsed SET doi_articleid = lower(doi_articleid);

-- create index
DROP INDEX IF EXISTS pmid_doi_parsed_idx;
CREATE INDEX pmid_doi_parsed_idx on public.pmid_doi_parsed(pmid,doi_articleid);

-- CREATE temp table with latest revision dates for multiple pmid cases
DROP TABLE IF EXISTS public.temp;
CREATE TABLE public.temp AS
select pmid, count(date_revised),max(date_revised)
from public.pmid_doi_parsed
group by pmid;
CREATE INDEX temp_idx ON public.temp(pmid,max);
SELECT COUNT(1) FROM public.temp;
SELECT COUNT (DISTINCT pmid) FROM public.temp;

DROP TABLE IF EXISTS public.temp2;
CREATE TABLE public.temp2 AS
SELECT pdp.pmid,pdp.doi_articleid,pdp.pub_year,t.max as latest_date_revised FROM pmid_doi_parsed pdp
INNER JOIN public.temp t ON pdp.pmid=t.pmid and pdp.date_revised=t.max;
SELECT COUNT(1) FROM public.temp2; --still has some duplicate pmids because of incremental doi changes
-- such as 10.12688/f1000research.25700.1 and 10.12688/f1000research.25700.2 both assigned to the
-- same pmid and with the same date_revised value.
-- It's probably worth keeping both dois for merging with Open Citations.`
DROP INDEX IF EXISTS temp2_idx;
CREATE INDEX temp2_idx ON public.temp2(pmid, doi_articleid);

-- remove rows where dois are duplicated
DELETE FROM public.temp2 WHERE doi_articleid IN
(SELECT doi_articleid FROM public.temp2 GROUP BY doi_articleid HAVING COUNT(pmid) > 1);
SELECT COUNT(1) FROM public.temp2; --26105525

DROP TABLE IF EXISTS pmid_doi_cleaned;
ALTER TABLE public.temp2 RENAME TO pmid_doi_cleaned;
SELECT COUNT(1) FROM pmid_doi_cleaned;

SELECT * FROM public.pmid_doi_cleaned LIMIT 5;

-- export cleaned and de-duplicated data to csv
COPY (SELECT * FROM public.pmid_doi_cleaned) TO '/tmp/pmid_doi_cleaned.csv' WITH(FORMAT CSV, HEADER);