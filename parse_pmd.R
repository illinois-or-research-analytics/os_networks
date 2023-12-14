# parses a compressed Pubmed XML file and returns a two column data frame.
# uses the syntax from https://rsangole.netlify.app/post/try-catch/

library(xml2)
library(data.table)
library(feather)
library(arrow)

parse_pmd <- function(x) {
	tryCatch(expr = {
		my_xml <- xml2::read_xml(x)
		v1 <- xml_text(xml_find_first(xml_children(my_xml), "./*/PMID"))
		v2 <- xml_text(xml_find_first(xml_children(my_xml), "./*/*/ELocationID[@EIdType='doi']"))
		v3 <- xml_text(xml_find_first(xml_children(my_xml), "./*/ArticleIdList/ArticleId[@IdType='doi']"))
		v4 <- xml_text(xml_find_first(xml_children(my_xml), "./*/DateRevised/Year"))
		v5 <- xml_text(xml_find_first(xml_children(my_xml), "./*/DateRevised/Month"))
		v6 <- xml_text(xml_find_first(xml_children(my_xml), "./*/DateRevised"))
		v7 <- xml_text(xml_find_first(xml_children(my_xml), "./*/*/*/*/PubDate/Year"))
		df <- data.frame(pmid = v1, doi_eloc = v2, doi_articleid =v3, date_revised = v6, year_revised = v4, month_revised = v5, pub_year = v7,stringsAsFactors = FALSE)
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

df_list <- list()
for (i in 1:length(file_list)) {
	df_list[[i]] <- parse_pmd(file_list[i])
	print(i); print(file_list[i])
}

# test for pmid NAs
lapply(df_list,function(x)setDT(x))
names(df_list) <- file_list
check_list <- lapply(df_list,function(x) x[is.na(pmid),.N])
names(check_list) <- file_list

# There must be a better way but...
z <- data.frame(as.list(unlist(check_list)))
check_df <- data.frame(file=names(z),pmid_na_count=unname(unlist(z)))
setDT(check_df)
if ( nrow(check_df[pmid_na_count > 0]) > 0) {
    print("Detected NAs in pmid column")
} else {
    print("No NAs detected")
}

print("Coalescing data frames and setting PMID to int")
pmid_doi_df <- rbindlist(df_list)
pmid_doi_df$pmid <- as.integer(pmid_doi_df$pmid)
# remove duplicate rows
pmid_doi_df <- unique(pmid_doi_df)

print("Exporting to csv and feather")
setwd('/shared/pubmed')
fwrite(pmid_doi_df,file='pmid_doi.csv')
write_feather(pmid_doi_df,'pmid_doi.feather')
write_parquet(pmid_doi_df,'pmid_doi_df.parquet')
fwrite(check_df,file="check_pmid_NAs.csv")

print("Done. Really!")





