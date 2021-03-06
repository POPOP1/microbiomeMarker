library(MicrobiomeAnalystR)
library(phyloseq)
library(magrittr)
# Human Moving Picture from MicrobiomeAnalyst server ----------------------

download.file("https://www.microbiomeanalyst.ca/MicrobiomeAnalyst/resources/data/treebiom.zip",
  "data-raw/caporaso.zip"
)
unzip("data-raw/caporaso.zip", exdir = "data-raw/")
file.rename("data-raw/treebiom/", "data-raw/caporaso/")

ps <- import_biom(
  "data-raw/caporaso/otu_table_mc2_w_tax_no_pynast_failures.biom",
  treefilename = "data-raw/caporaso/rep_set.tre",
)

colnames(tax_table(ps)) <- c("Kingdom", "Phylum", "Class", "Order",
  "Family", "Genus", "Species")

sampledata <- read.delim("data-raw/caporaso/map.txt", row.names = 1) %>%
  sample_data()
caporaso_phyloseq <- merge_phyloseq(ps, sampledata)

usethis::use_data(caporaso_phyloseq, overwrite = TRUE)
unlink("data-raw/cap*", recursive = TRUE)


# cid data from github.com/ying14/yingtools2 ------------------------------
download.file(
  "https://github.com/ying14/yingtools2/raw/master/data/cid.phy.rda",
  "data-raw/cid.phy.rda"
)
load("data-raw/cid.phy.rda")
usethis::use_data(cid.phy, overwrite = TRUE)
unlink("data-raw/cid*")

# pediatric ibd -----------------------------------------------------------

# https://www.microbiomeanalyst.ca/MicrobiomeAnalyst/resources/data/ibd_data.zip
download.file(
  "https://www.microbiomeanalyst.ca/MicrobiomeAnalyst/resources/data/ibd_data.zip",
  "data-raw/pediatric_idb.zip"
)
unzip("data-raw/pediatric_idb.zip", exdir = "data-raw/")
asv_abundance <- readr::read_tsv("data-raw/ibd_data/IBD_data/ibd_asv_table.txt") %>%
  tibble::column_to_rownames("#NAME")
asv_table <- readr::read_tsv("data-raw/ibd_data/IBD_data/ibd_taxa.txt") %>%
  tibble::column_to_rownames("#TAXONOMY")
sample_table <- readr::read_csv("data-raw/ibd_data/IBD_data/ibd_meta.csv") %>%
  tibble::column_to_rownames("#NAME")
pediatric_ibd <- phyloseq(
  otu_table(asv_abundance, taxa_are_rows = TRUE),
  tax_table(as.matrix(asv_table)),
  sample_data(sample_table)
)
tree <- read_tree(treefile = "data-raw/ibd_data/IBD_data/ibd_tree.tre")
phy_tree(pediatric_ibd) <- tree
usethis::use_data(pediatric_ibd, overwrite = TRUE)
unlink("data-raw/ibd_data", recursive = TRUE)
unlink("data-raw/pediatric_idb.zip")


# oxygen availability -----------------------------------------------------
# a small subset of the HMP 16S dataset for finding biomarkers characterizing
# different level of oxygen availability in different bodysites

oxygen_dat <- readr::read_tsv(
  "http://huttenhower.sph.harvard.edu/webfm_send/129",
  col_names = FALSE
)

sample_meta <- dplyr::bind_rows(
  oxygen_availability	= oxygen_dat[1, ][-1],
  body_site = oxygen_dat[2, ][-1],
  subject_id = oxygen_dat[3, ][-1]
) %>%
  tibble::rownames_to_column() %>%
  tidyr::pivot_longer(-rowname) %>%
  tidyr::pivot_wider(names_from = "rowname", values_from = "value") %>%
  tibble::column_to_rownames("name")
tax_dat <- oxygen_dat$X1[-(1:3)]

sample_abd <- dplyr::slice(oxygen_dat, -(1:3)) %>%
  select(-1) %>%
  purrr::map_df(as.numeric)
row.names(sample_abd) <- tax_dat

tax_mat <- as.matrix(tax_dat)
row.names(tax_mat) <- tax_dat
colnames(tax_mat) <- "Summarize"

oxygen <- phyloseq(
  otu_table(sample_abd, taxa_are_rows = TRUE),
  tax_table(tax_mat),
  sample_data(sample_meta)
)

usethis::use_data(oxygen, overwrite = TRUE)

# data from lefse galaxy --------------------------------------------------
# Fecal microbiota in a mouse model of spontaneous colitis. The dataset contains
# 30 abundance profiles (obtained processing the 16S reads with RDP) belonging
# to 10 rag2 (control) and 20 truc (case) mice
spontaneous_colitis <- readr::read_tsv(
  "http://www.huttenhower.org/webfm_send/73",
  col_names = FALSE
)
class <- spontaneous_colitis[1, ]
taxas <- spontaneous_colitis[, 1]

sample_meta <- data.frame(
  class = unlist(class[-1]),
  stringsAsFactors = FALSE
)
tax_dat <- as.matrix(taxas[-1, ])
row.names(tax_dat) <- tax_dat
colnames(tax_dat) <- "summarized_taxa"
tax_abd <- spontaneous_colitis[-1, -1] %>%
  purrr::map_df(as.numeric)
row.names(tax_abd) <- tax_dat[,1]

spontaneous_colitis <- phyloseq(
  otu_table(tax_abd, taxa_are_rows = TRUE),
  tax_table(tax_dat),
  sample_data(sample_meta)
)

usethis::use_data(spontaneous_colitis, overwrite = TRUE)

# Enterotypes data from Arumugam's paper from stamp -----------------------

enterotypes_arumugam <- readr::read_tsv("https://github.com/yiluheihei/STAMP/raw/master/examples/EnterotypesArumugam/Enterotypes.profile.spf")

enterotypes_arumugam_meta <- readr::read_tsv("https://github.com/yiluheihei/STAMP/raw/master/examples/EnterotypesArumugam/Enterotypes.metadata.tsv") %>% as.data.frame()
row.names(enterotypes_arumugam_meta) <- enterotypes_arumugam_meta$`Sample Id`

enterotype_abd <- dplyr::select(enterotypes_arumugam, -Phyla, -Genera)
enterotype_tax <- dplyr::select(enterotypes_arumugam, Phylum = Phyla, Genus = Genera)

enterotypes_arumugam <- phyloseq(
  otu_table(enterotype_abd, taxa_are_rows = TRUE),
  tax_table(as.matrix(enterotype_tax)),
  sample_data(enterotypes_arumugam_meta)
)

usethis::use_data(enterotypes_arumugam, overwrite = TRUE)
