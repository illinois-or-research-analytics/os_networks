-- process pmids and dois parsed from PubMed using parse_pmd.R
-- load pmid_doi.csv into the public.pmid_doi_parsed table

-- remove null PMID rows
SELECT COUNT(1) from public.pmid_doi_parsed; --36416016
DELETE from public.pmid_doi_parsed WHERE pmid IS NULL; --36416015

SELECT COUNT(1) FROM pmid_doi_parsed where doi_eloc is null; --20012712
SELECT COUNT(1) FROM pmid_doi_parsed where doi_articleid is null; --8884053
SELECT COUNT(1) FROM pmid_doi_parsed where doi_articleid != doi_eloc AND doi_eloc is not null; --15566

--eliminate all pmids where doi_articleid is null or empty string
DELETE FROM public.pmid_doi_parsed where doi_articleid is null;
DELETE FROM public.pmid_doi_parsed where doi_articleid = '';

-- force lower case on all dois
UPDATE public.pmid_doi_parsed SET doi_articleid = lower(doi_articleid);

-- create index
DROP INDEX IF EXISTS pmid_doi_parsed_idx;
CREATE INDEX pmid_doi_parsed_idx on public.pmid_doi_parsed(pmid,doi_articleid);

DELETE FROM pmid_doi_parsed WHERE PMID IN
(SELECT pmid FROM pmid_doi_parsed GROUP BY pmid HAVING COUNT(doi_articleid) > 1);

DELETE FROM pmid_doi_parsed WHERE doi_articleid IN
(SELECT doi_articleid FROM pmid_doi_parsed GROUP BY doi_articleid HAVING COUNT(pmid) > 1);

SELECT COUNT(1) from public.pmid_doi_parsed;

-- export cleaned and de-duplicated data to csv
COPY (SELECT * FROM public.pmid_doi_parsed) TO '/tmp/pmid_doi_cleaned.csv' WITH(FORMAT CSV, HEADER);