



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
  x <- gsub("[[:punct:]]","",x)
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
    return(x)
  })

  # Remove defective entries (some fail to be fetched and are incomplete)
  c <- c[(1:length(c))[unlist(lapply(c,length)) == 4]]

  # Reformat
  c <- lapply( c , function(x) {
    z <- c(
      DATE = sub(".*[.] ","",sub(";.*","",x[1])),
      PMID = ifelse(grepl("PMID",x[4]),sub(" .*","",sub(".*PMID: ","",x[4])),""),
      TITLE = x[2],
      JOURNAL = sub("[.] .*","",x[1]),
      YEAR = sub(" .*","",sub(".*[.] ","",sub(";.*","",x[1]))),
      DOI = ifelse(grepl("doi",x[1]),sub("[.] .*","",sub(".*doi: ","",x[1])),"") ,
      AUTHORS = x[3]
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

# Merge all publications
tmp2 <- do.call(rbind,tmp)

# Filter publications
tmp2 <- tmp2[!is.na(as.numeric(tmp2$IF)),]
tmp2 <- tmp2[as.numeric(tmp2$IF) > 20,]
tmp2 <- tmp2[!is.na(tmp2$TITLE),]
tmp2 <- tmp2[!grepl("Author Correction: ",tmp2$TITLE),]
tmp2 <- tmp2[!is.na(as.numeric(tmp2$YEAR)),]
tmp2 <- tmp2[as.numeric(tmp2$YEAR) > 2015,]
tmp2 <- tmp2[order(as.numeric(tmp2$YEAR),decreasing = T),]

write.csv(tmp2,"../compiled/publications/paper_news.csv")
