

# Read the list of datasets stored on UPPMAX
url <- xml2::read_html('https://export.uppmax.uu.se/snic2022-23-113/datasets/')

# Convert the HTML output to a list and iterate over all datasets
url <- xml2::as_list(url)
tmp <- lapply(url$html$body$ul , function(x){x[[1]][[1]]})[c(T,F)]
tmp <- unlist(tmp)
dataset_list <- as.character(gsub("[ /]","",tmp[-1]))

# Download each dataset in the 'data' foldet
for(i in dataset_list){
  download.file(url = paste0('https://export.uppmax.uu.se/snic2022-23-113/datasets/',i,'/',i,'_metadata.csv'),
                destfile = paste0('../data/',i,'_metadata.csv'))
}

# Compile all datasets into a single file and save it to this repo
dl <- list.files('../data',full.names = T,recursive = T)
dl <- lapply(dl,function(x){read.csv(x,row.names=1)})
dl <- do.call(rbind, dl)
dim(dl)

write.csv(dl,'../compiled/all_datasets.csv',row.names=T)




