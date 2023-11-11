import xml.etree.ElementTree as ET

# Load and parse the XML file
tree = ET.parse('missing_pmids.xml')
root = tree.getroot()

# Find all PubmedArticle elements 
articles = root.findall('.//PubmedArticle')

# start line number from 1
line_number = 1

# Two lines are added to format lines
# Define the maximum expected length of line numbers (20 millions?)
line_number_width = 8 
doi_width = 60  # Adjust this based on the longest expected DOI

# Search DOI and PMID for each article
for article in articles:
    pmid_element = article.find('.//PMID')
    # Initialize doi as 'DOI not available' in case it's not found
    doi = 'DOI is not available'
    if pmid_element is not None:
        pmid = pmid_element.text
        
        # Find the ArticleIdList from the direct child of the PubmedData, excluding the ArticleIdList elements from the ReferenceList
        pubmed_data = article.find('.//PubmedData')
        if pubmed_data is not None:
            article_id_list = pubmed_data.find('.//ArticleIdList')

            if article_id_list is not None:
                doi_element = article_id_list.find('.//ArticleId[@IdType="doi"]')

                # Update doi if the element is found
                if doi_element is not None:
                    doi = doi_element.text

        print(f'{line_number:<{line_number_width}}: {doi:<{doi_width}} {pmid}')

    else:
        pmid = 'PMID is not available'
        print(f'{line_number:<{line_number_width}}: {doi:<{doi_width}} {pmid}')
    
    line_number += 1
