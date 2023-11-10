-- process pmids and dois parsed from PubMed using parse_pmd.R
-- load pmid_doi.csv into the public.pmid_doi_parsed table

-- remove null PMID rows
SELECT COUNT(1) from public.pmid_doi_parsed;
DELETE from public.pmid_doi_parsed WHERE pmid IS NULL;

--eliminate all pmids where doi is null or empty string
DELETE FROM public.pmid_doi_parsed where doi is null;
DELETE FROM public.pmid_doi_parsed where doi = '';

-- force lower case on all dois
UPDATE public.pmid_doi_parsed SET doi = lower(doi);

-- create index
DROP INDEX IF EXISTS pmid_doi_parsed_idx;
CREATE INDEX pmid_doi_parsed_idx on public.pmid_doi_parsed(pmid,doi);

-- export to CSV and use unique in R to easily suppress duplicates.
-- truncate table and reload de-duplicated.

-- check for duplicate pmids, dois, etc. and delete
DELETE FROM pmid_doi_parsed WHERE PMID IN
(SELECT pmid FROM pmid_doi_parsed GROUP BY pmid HAVING COUNT(doi) > 1);

DELETE FROM pmid_doi_parsed WHERE doi IN
(SELECT doi FROM pmid_doi_parsed GROUP BY doi HAVING COUNT(pmid) > 1);

SELECT COUNT(1) from public.pmid_doi_parsed;
