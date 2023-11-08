# os_networks
A general approach for constructing citation networks using open resources where possible. The idea is to take a publication(s) of interest and perform
a BFS-ish expansion around it to capture local and relatively local citations. Our test case is a PI 3-Kinase network constructed from a review by Fruman 
et al. (2017) in Cell. 10.1016/j.cell.2017.07.029 The review has 291 references. Of these, we were able to extract 283 dois using Scopus. These 283 dois
were joined with dois in the Open Citations network (a 2023 download by us) to extract a set of citing and citing nodes, which were combined with the seed
references to form a Stage I set. A second set of citing and cited nodes were collected using the same approach. After deduplication, the nodes were used
to induce a subgraph consisting of 427496813 edges and 15,026,612 nodes.

The next stage is to restrict the network further to those nodes that are found in PubMed so that metadata can be collected for them for various analytical
purposes. For this, we download Pubmed using EDirect and parse the downloaded files to create a lookup table of pmid <-> doi. This is in progress. 
