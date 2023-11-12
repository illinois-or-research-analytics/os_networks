# parses a compressed Pubmed XML file and returns a two column data frame.

library(XML)
library(xml2)
library(data.table)
my_xml <- xml2::read_xml("missing_pmids.xml")

###### Initial approacj with find_all
# find_all does not return NAs
v1 <- xml_text(xml_find_all(my_xml, "./*/*/PMID"))
v2 <- xml_text(xml_find_all(my_xml, "./*/*/*/ELocationID[@EIdType='doi']"))

df <- data.frame(pmid = v1, doi = v2, stringsAsFactors = FALSE)
print(df)
######

######
# # alternate better version- find_first does
# parse_pmd <- function(xml_file) {
#	my_xml <- xml2::read_xml(xml_file)
#	v1 <- xml_text(xml_find_first(xml_children(my_xml), "./*//PMID"))
#	v2 <- xml_text(xml_find_first(xml_children(my_xml), "./*/*/ELocationID[@EIdType='doi']"))
#
#	df <- data.frame(pmid = v1, doi = v2, stringsAsFactors = FALSE)
#	return(df)
# }
#######
# even better, using the syntax from https://rsangole.netlify.app/post/try-catch/

parse_pmd <- function(x) {
	tryCatch(expr = {
		my_xml <- xml2::read_xml(x)
		v1 <- xml_text(xml_find_first(xml_children(my_xml), "./*//PMID"))
		v2 <- xml_text(xml_find_first(xml_children(my_xml), "./*/*/ELocationID[@EIdType='doi']"))
		df <- data.frame(pmid = v1, doi = v2, stringsAsFactors = FALSE)
		return(df)

	}, error = function(e) {
		message("Error!")
		print(e)
		stop("Halting")
	}, warning = function(w) {
		message("Warning!")
		print(w)
	}, finally = {
		message("All done")
	})
}

system.time({
test_df <- data.frame() 
for (i in 1:length(file_list)) {
temp <- parse_pmd(file_list[i])
test_df <- rbindlist(list(test_df,temp))
}}
)