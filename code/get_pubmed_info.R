#!/home/ubuntu/opt/R/bin/Rscript

library(RISmed)
library(future)
library(future.apply)



# Get journal Impact Factor
IF <- as.data.frame(readxl::read_xlsx("../data/latestJCRlist2022.xlsx"))
print(head(IF))
#colnames(IF) <- IF[1,]
#IF <- IF[-1,]
IF$journal_name <- casefold(IF$journal_name)
print(head(IF))



# Function to format article list
reformat_journal_name <- function(journals){
  journals <- casefold(journals)
  journals <- gsub(" [(:.;].*","",journals)
  journals <- gsub("&amp;","&",journals)
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



# Match IF for each publication
terms <- c('Joakim Lundeberg',
           'Emma Lundberg',
           'Mats Nilsson',
           'Sten Linnarsson',
           'Christos Samakovlis',
           'Erik Sundström')
# terms <- c('Czarnewski')

all_info <- future_lapply(terms , function(x){
  message(paste0('processing:\t',x))
  x <- fix_names(x)
  # search_topic <- EUtilsQuery(x) 
  search_query <- EUtilsSummary(x)
  records <- EUtilsGet(search_query)
  return(records)
})
names(all_info) <- terms


res <- lapply(all_info , function(x){
  journals <- reformat_journal_name(x@Title)
  print(journals)
  xxx <- as.numeric(IF$if_2022[ match( journals , IF$journal_name ) ])
  return( setNames( xxx , journals )  )
})
names(res) <- terms




min_if <- 5
year_cutoff <- 2010
topN <- 20
all_pubs <- list()


for(i in names(all_info)){
  message(paste0("Proscessing: ",i))

  sel2 <- all_info[[i]]@YearPubmed >= year_cutoff
  
  if_cutoff <- sort(res[[i]][sel2],decreasing = T)[ topN ]
  
  sel <- res[[i]] >= if_cutoff
  sel3 <- res[[i]] >= min_if
  sel4 <- !grepl("Publisher[ ]Correction|Author[ ]Correction",all_info[[i]]@ArticleTitle)

  tmp <- all_info[[i]]
  xxx <- lapply( c("YearPubmed","MonthPubmed","DayPubmed"),function(x) attr(tmp,x) )
  xxx <- sapply( 1:length(xxx[[1]]) , function(x){ 
    paste0(xxx[[1]][x],"-",sprintf("%02d",xxx[[2]][x]),"-",sprintf("%02d",xxx[[3]][x])  ) } )
  filters <- cbind(sel2,sel,sel3,sel4,
                   DATE=xxx,
                   PMID=tmp@PMID,
                   YEAR=tmp@YearPubmed,
                   IF=res[[i]],
                   JOURNAL=gsub(" [(].*","",tmp@Title),
                   ARTICLE=tmp@ArticleTitle,
                   AUTHORS=  sapply(tmp@Author,function(x){ 
                     x[is.na(x)] <- ""
                     z <- paste0(x$CollectiveName,paste0(x$LastName," ",x$Initials) )
                     z  <- paste0(z,collapse = ", ")
                     return(z)
                   }) )
  
  sels <- grep( "1", as.logical(filters[,1])*as.logical(filters[,2])*as.logical(filters[,3])*as.logical(filters[,4]) )
  all_pubs[[i]] <- filters[sels,]

  con <- file(paste0("../compiled/publications/",i,'.txt'))
  sink(con,append=TRUE)
  sink(con,append=TRUE,type="message")

  for(j in sels){
    k <- tmp@PMID[j]
    tmp2 <- tmp@Author[[k]]
    tmp2[is.na(tmp2)] <- ""
    tmp2$LastName <- paste0(tmp2$CollectiveName,tmp2$LastName)
    
    x <- paste0(paste0( tmp2$LastName ," ", tmp2$Initials ,collapse = ", "),". ")
    x1 <- paste0(sub(".* ","",i), " ", substring(sub(" .*","",i), 1, 1) )
    if( grepl( paste0(x1,"[,.] "), x ) ){
      x <- gsub(x1 , paste0("<u>",x1,"</u>"), x)
    }
    
    cat( "<p>" )
    cat( paste0( x ) )
    cat( paste0("<b>", tmp@ArticleTitle[[j]],"</b>") )
    cat( "\n" )
    cat( paste0("<a href='https://doi.org/",tmp@DOI[[j]],"'>") )
    cat( paste0( tmp@Title[[j]]) )
    cat( "</a>" )
    cat( paste0( " (" , month.abb[ tmp@MonthPubmed[[j]] ]," ", tmp@YearPubmed[[j]],") " ) )
    
    cat( "</p>" )
    cat( "\n\n" )

  }
  
  sink() 
  sink(type="message")
}






all_pubs2 <- as.data.frame( do.call( rbind , all_pubs ) )
all_pubs2 <- all_pubs2[ ,-c(1:4) ]
all_pubs2 <- all_pubs2[ ! duplicated(all_pubs2) , ]
all_pubs2 <- all_pubs2[ as.numeric( all_pubs2$IF ) > 10 , ]
all_pubs2 <- all_pubs2[ as.numeric( all_pubs2$YEAR ) > 2019 , ]
all_pubs2 <- all_pubs2[ order( all_pubs2$YEAR , decreasing = T) , ]

dim(all_pubs2)

all_pubs2$JOURNAL

tmp <- all_info[[1]]
for(i in slotNames(tmp)){
  valll <- lapply(all_info ,i=i, function(x,i) return(slot(x,i)))
  
  print(typeof(slot(tmp,i) ))
  print(typeof(valll[[1]]))
  
  if( is.list( valll[[1]] ) ){
    valll <- do.call(c,valll)
    names(valll) <- sub(".*[.]","",names(valll))
    slot(tmp, i) <- valll
  } else {
    slot(tmp, i) <- unlist(valll) 
  }
}
write.csv(all_pubs2 , "../compiled/publications/paper_news2.csv",row.names = F)




con <- file(paste0('../compiled/publications/paper_news.txt'))
sink(con,append=TRUE)
sink(con,append=TRUE,type="message")
sink(con,append=TRUE,type="message")
cat( "<h3>RECENT PUBLICATIONS</h3>\n\n" )
for(j in match( all_pubs2$PMID , tmp@PMID ) ){
  k <- tmp@PMID[j]
  cat( "<p>" )
  cat( paste0("<b>",tmp@YearPubmed[[j]],"-",tmp@MonthPubmed[[j]],"-",tmp@DayPubmed[[j]] ,"</b>\n") )
  cat( paste0("<b>", tmp@Title[[j]] , "</b>. ") )
  cat( paste0("<a href='https://doi.org/",tmp@DOI[[j]],"'>") )
  cat( paste0( tmp@ArticleTitle[[j]] ) )
  cat( "</a>" )
  # cat( "\n" )
  
  tmp2 <- tmp@Author[[k]]
  tmp2[is.na(tmp2)] <- ""
  tmp2$LastName <- paste0(tmp2$CollectiveName,tmp2$LastName)
  
  x <- paste0(paste0( tmp2$LastName ," ", tmp2$Initials ,collapse = ", "),".")
  x1 <- paste0(sub(".* ","",i), " ", substring(sub(" .*","",i), 1, 1) )
  if( grepl( paste0(x1,"[,.] "), x ) ){
    x <- gsub(x1 , paste0("<u>",x1,"</u>"), x)
  }
  cat( paste0(". ", x ) )
  cat( "</p>" )

  cat( "\n\n" )

}
  cat( "<hr>" )
  cat( "\n\n" )

sink() 
sink(type="message")



