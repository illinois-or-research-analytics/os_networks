select count(1) from public.pi3k_nl;

CREATE TABLE public.pi3k_pubmed_restricted_nl AS
SELECT pn.iid,pdp.pmid,ocp.doi from public.pi3k_nl pn
INNER JOIN public.open_citation_pubs ocp
ON ocp.iid=pn.iid
INNER JOIN public.pmid_doi_parsed pdp
ON pdp.doi=ocp.doi;

SELECT COUNT(1) FROM pi3k_pubmed_restricted_nl;

CREATE TABLE pi3k_pubmed_restricted_el AS
SELECT pe.citing_iid, pe.cited_iid FROM pi3k_el pe
INNER JOIN public.pi3k_pubmed_restricted_nl pn1
ON pe.citing_iid=pn1.iid
INNER JOIN public.pi3k_pubmed_restricted_nl pn2
ON pe.cited_iid=pn2.iid;

SELECT COUNT(1) FROM pi3k_pubmed_restricted_el;