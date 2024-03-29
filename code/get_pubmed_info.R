


suppressMessages(suppressWarnings({

# Function to format article list
reformat_journal_name <- function(journals){
  journals <- casefold(journals)
  journals <- gsub(" [(:.;].*","",journals)
  journals <- gsub("[-.].*","",journals)
  journals <- gsub("&amp;","&",journals)
  journals <- gsub("&","and",journals)
  journals <- gsub(",","",journals)
  journals <- gsub("^the ","",journals)
  journals <- gsub("'","",journals)
  return(journals)
}

fix_names <-  function(x){
  x <- iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT')
  # x <- gsub("[[:punct:]]","",x)
  return(x)
}

#Get Pubmed Journal abreviations isoAbbr
if(!file.exists("../data/J_Medline.txt")){
  dir.create("../data",recursive = T)
  download.file("https://ftp.ncbi.nih.gov/pubmed/J_Medline.txt","../data/J_Medline.txt")
}
JA <- readLines("../data/J_Medline.txt")
JA <- data.frame(
  JournalTitle = reformat_journal_name(gsub("JournalTitle: ","",JA[grep("JournalTitle",JA)])),
  IsoAbbr = reformat_journal_name(gsub("IsoAbbr: ","",JA[grep("IsoAbbr",JA)])) )

# Get journal Impact Factor
IF <- as.data.frame(readxl::read_xlsx("../data/2020ImpactFactordetail.xlsx",skip = 2))
IF$journal_name <- reformat_journal_name(IF$`Full Journal Title`)
# Read in output from 'abstract'
# esearch -db pubmed -query 'Joakim Lundeberg' | efetch -format abstract > ../data/publications/JL.txt
file_list <- list.files("../data/publications",full.names = T,pattern = ".txt")
tmp <- lapply( file_list , function(i){
  a <- readLines(i)

  # Merge all lines into a single string (empty replaced by "BREAKKBREAKK")
  a[a==""] <- "BREAKK"
  a <- paste(a , collapse = " ")

  # Split articles
  b <- strsplit( a , split = "BREAKK BREAKK")[[1]]
  b <- lapply( b , function(x) {
    # Remove empty space from start of string
    x <- gsub("^ ","",x)
    # Remove 'BREAKK' from start of string
    x <- gsub("^BREAKK","",x)
    # Remove query numbers from the start
    x <- gsub("^[0-9]+?[.] ","",x)
    return(x)
  })

  # Split the article information into strings
  c <- lapply( b , function(x) {
    x <- strsplit( x , split = "BREAKK")[[1]]
    # Remove empty space from start of string
    x <- gsub("^ ","",x)
    x <- gsub(" $","",x)
    # Remove query numbers from the start
    x <- gsub("^[0-9]+?[.] ","",x)
    return(x)
  })


  # Remove defective entries (some fail to be fetched and are incomplete)
  c <- c[(1:length(c))[unlist(lapply(c,length)) >= 3]]

  # Select on the JOUNAL, TITLE, AUTHOR_NAMES and PMID
  c <- lapply( c , function(x) {
    x <- x[ c(1:3,grep("PMID",x)) ]
    x <- gsub("[(][0-9]+?[)]","",x)
    x <- gsub("[(]#[)]","*",x)
    x <- gsub("  "," ",x)
    return(x)
  })

  # Remove defective entries (some fail to be fetched and are incomplete)
  c <- c[(1:length(c))[unlist(lapply(c,length)) == 4]]

  # Reformat
  c <- lapply( c , function(x) {
    z <- c(
      DATE = sub(".*[.] ","",sub(";.*","",x[1])),
      PMID = ifelse(grepl("PMID",x[4]),sub(" .*","",sub(".*PMID: ","",x[4])),""),
      TITLE =  gsub("[.]$","",x[2]),
      JOURNAL = sub("[.] .*","",x[1]),
      YEAR = sub(" .*","",sub(".*[.] ","",sub(";.*","",x[1]))),
      DOI = gsub("[.]$","",ifelse(grepl("doi",x[1]),sub("[.] .*","",sub(".*doi: ","",x[1])),"")) ,
      AUTHORS = fix_names(x[3])
    )
    return(z)
  })

  d <- do.call(rbind,c)
  d <- as.data.frame(d)
  d$JOURNAL <- gsub(' [(].*','',d$JOURNAL)
  d$FULL_JOURNAL_NAME <- JA[ match(reformat_journal_name(d$JOURNAL) , JA$IsoAbbr) , "JournalTitle"]

  d$IF <- IF[ match(reformat_journal_name(d$FULL_JOURNAL_NAME) , IF$journal_name) , "Journal Impact Factor"]
  return(d)
})
names(tmp) <- file_list

# Remove bad-formated or less relevant entries
tmp <- lapply( tmp , function( i ){
  # Filter publications
  i <- i[!is.na(as.numeric(i$IF)),]
  i <- i[as.numeric(i$IF) > 20,]
  i <- i[!is.na(i$TITLE),]
  i <- i[!grepl("Author Correction: ",i$TITLE),]
  i <- i[!is.na(as.numeric(i$YEAR)),]
  i <- i[as.numeric(i$YEAR) > 2015,]
  i <- i[order(as.numeric(i$YEAR),decreasing = T),]
  i <- i[, c("DATE","PMID","YEAR","IF","JOURNAL","TITLE","AUTHORS","DOI","FULL_JOURNAL_NAME")]
})


# Export publications per PI
lapply( names(tmp) , function( i ){
  write.csv( tmp[[i]] , gsub(".txt$",".csv",gsub("data","compiled",i)) )
})

# Merge all publications and export
tmp2 <- do.call(rbind,tmp)
tmp2 <- tmp2[order(as.numeric(tmp2$PMID),decreasing = T),]
rownames(tmp2) <- 1:nrow(tmp2)
write.csv(tmp2,"../compiled/publications/paper_news.csv")


}))

#
