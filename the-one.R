#### Load packages, set constants ####
if (!require(pacman)) {
  install.packages(pacman)
}
library(pacman)

p_load(tidyverse, tools)

# Place downloaded Galaxy obs count in ./galaxy-download
# Place SraRunTable.txt in ./ 
# Create all folders listed below

dir_in <- "./galaxy-download"
dir_out <- "./galaxy-upload"

#### Import count data, combine with metadata ####
count <- tibble(dir = fs::dir_ls(dir_in),
                filename = str_extract(dir, "[^/]+$"),
                GSM = file_path_sans_ext(fs::dir_ls(dir_in)) %>%          # Generate table with file directory, filename, GSM
                  str_extract("[^/]+$")) %>%
  mutate(content = map(dir, ~ read_tsv(file = .x)))                       # Add count data to table

metadata <- read_csv("./SraRunTable.txt") %>%                             # Generate clean metadata list
  filter(library_type == "single-nucleus RNA sequencing") %>%             # Filter for snRNA samples
  select(`GEO_Accession (exp)`, sample_group, gender, region) %>%         # Choose metadata params to keep
  rename(GSM = `GEO_Accession (exp)`)

count <- left_join(count, metadata) %>%                                   # Combine metadata with count data
  unnest() %>%
  select(!`...1`) %>%
  group_by(GSM) %>%
  nest(cols = !c(dir, filename))

#### Export to ./galaxy-upload ####
map2(count$cols, count$filename,
     ~write_delim(.x, 
                  file = str_c(dir_out, "/", .y, sep = ""),
                  delim = "\t",
                  append = FALSE))

#### Afterwards: #### 
# Upload content of ./galaxy-upload to Galaxy as a collection. 
# Sort both AnnData and metadata collections, then add annotations with scanpy.