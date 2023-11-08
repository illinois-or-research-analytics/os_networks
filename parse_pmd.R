# parses a compressed Pubmed XML file and returns a two column data frame.
# uses the syntax from https://rsangole.netlify.app/post/try-catch/
library(xml2)
library(data.table)

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
setwd('/shared/pubmed_copy')
file_list <- list.files(pattern="*.xml.gz")
for (i in 1:100) {
temp <- parse_pmd(file_list[i])
fwrite(temp,file=paste0('/shared/pubmed/',file_list[i],'.csv'))
}