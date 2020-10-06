
# PURPOSE -----------------------------------------------------------------

#' To process the manually curated existing GRiP pediatric ADE gold standard
#' 
#' 

#' EXAMPLE RUN:
#' ----------------------
#' 
#' Rscript GRiP_Pediatric_ADE_Gold_Standard_Processing.R ../../data/GRiP_Pediatric_ADE_Gold_Standard_List.xlsx
#' 
#' 
# load libraries ----------------------------------------------------------

if (!require("pacman")) install.packages("pacman")
pacman::p_load("readxl", "tidyverse", "DBI","data.table")

# load data ---------------------------------------------------------------

args = commandArgs(trailingOnly=TRUE)

filepath <- args[1]
#filepath <- "../../data/GRiP_Pediatric_ADE_Gold_Standard_List.xlsx"
path <- paste0(
  paste0(strsplit(filepath,"/")[[1]][1:3],collapse="/"),
  "/"
  )
reaction_code_map <- read_xlsx(filepath,sheet = 1)
drug_reaction_map <- read_xlsx(filepath,sheet = 2)
grading_map <- read_xlsx(filepath,sheet = 3)
definition_map <- read_xlsx(filepath,sheet = 4)
sources <- read_xlsx(filepath,sheet = 5,col_names = F) %>% 
  unlist %>% unname


# join --------------------------------------------------------------------

full_joined <- inner_join(reaction_code_map,drug_reaction_map,
           by=c("Event_name","Medical_definition")) %>% 
  left_join(grading_map,by=c("Level_of_epidemiological_evidence","Grade")) %>% 
  select(-contains(".y")) %>% 
  select(-contains(".x"))

#Missing OL, SMQ terms...
#Matching event types to what's in OHDSI
full_joined$Code_type[full_joined$Code_type=="LT"] = "LLT"
full_joined$Code_type[full_joined$Code_type=="HT"] = "HLT"
full_joined$Code_type[full_joined$Code_type=="HG"] = "HLGT"

# Get ohdsi vocabulary and join -------------------------------------------

concept <- 
  fread("../../data/vocabulary_various/CONCEPT.csv") %>% 
  .[vocabulary_id %in% c("ATC","MedDRA","SNOMED","RxNorm")]

concept_relationship <- 
  fread("../../data/vocabulary_various/CONCEPT_RELATIONSHIP.csv")


# mapping and join MedDRA and ATC -----------------------------------------

codes <- unique(full_joined$MedDRA_code)

c <- 
  concept[concept_code %in% codes] %>% 
  mutate(
    concept_code = as.numeric(concept_code)
  )

colnames(c) <- paste0("MedDRA_",colnames(c))

joined_MedDRA <- inner_join(full_joined,c,
                      by=c("MedDRA_code"="MedDRA_concept_code",
                           "Code_type"="MedDRA_concept_class_id")) %>% 
  mutate(
    MedDRA_concept_code = MedDRA_code
  )

codes <- unique(full_joined$ATC_code)

c <- 
  concept[concept_code %in% codes]

colnames(c) <- paste0("ATC_",colnames(c))

joined_MedDRA_ATC <- inner_join(joined_MedDRA,c,
                                by=c("ATC_code"="ATC_concept_code"))

# map MedDRA to SNOMED ----------------------------------------------------


joined_MedDRA_ATC_MedDRA_relations_c <- joined_MedDRA_ATC %>% 
  mutate(
    MedDRA_concept_class_id = Code_type
  )

codes <- unique(joined_MedDRA_ATC_MedDRA_relations_c$MedDRA_concept_id)
cr <- concept_relationship[
  (concept_id_1 %in% codes) & (relationship_id=="MedDRA - SNOMED eq")
  ]

snomed_ids <- concept[
  (vocabulary_id %in% c("SNOMED") & 
           concept_id %in% cr$concept_id_2)] %>% 
  select(concept_id) %>% 
  distinct() %>% unlist %>% unname

cr_snomed_ids <- cr %>% 
  filter(concept_id_2 %in% snomed_ids)

colnames(cr_snomed_ids) <- paste0("SNOMED_relation_",colnames(cr_snomed_ids))

joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations <- 
  left_join(joined_MedDRA_ATC_MedDRA_relations_c,cr_snomed_ids,
            by=c("MedDRA_concept_id"="SNOMED_relation_concept_id_1"))

codes <- unique(joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations$SNOMED_relation_concept_id_2)

c <- concept[concept_id %in% codes & vocabulary_id=="SNOMED"]

colnames(c) <- paste0("SNOMED_",colnames(c))

joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c <- 
  left_join(joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations,c,
          by=c("SNOMED_relation_concept_id_2"="SNOMED_concept_id")) %>% 
  mutate(
    SNOMED_concept_id = SNOMED_relation_concept_id_2
  )


# map ATC/RxNorm relationships -------------------------------------------------------

codes <- unique(joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c$ATC_concept_id)

cr <- concept_relationship[(concept_id_1 %in% codes)]

ingredients <- concept[concept_id %in% cr$concept_id_2 & 
           concept_class_id=="Ingredient"] %>% 
  select(concept_id) %>% unlist %>% unname

cr_ings <- cr %>% 
  filter(concept_id_2 %in% ingredients)

colnames(cr_ings) <- paste0("RxNorm_relation_",colnames(cr))

joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations <- 
  left_join(joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c,cr_ings,
            by=c("ATC_concept_id"="RxNorm_relation_concept_id_1")) 


# map from ATC to RxNorm --------------------------------------------------

codes <- unique(joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations$RxNorm_relation_concept_id_2)

c <- concept[concept_id %in% codes]

colnames(c) <- paste0("RxNorm_",colnames(c))

joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm <- 
  left_join(joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations,
            c %>% filter(RxNorm_vocabulary_id=="RxNorm"),
            by=c("RxNorm_relation_concept_id_2"="RxNorm_concept_id")) %>% 
  rename(
    RxNorm_concept_id = RxNorm_relation_concept_id_2
  )

# output ------------------------------------------------------------------

db <- "user_npg2108"

con <- DBI::dbConnect(RMySQL::MySQL(),
                      user = readr::read_tsv("../../.my.cnf")$u,
                      password = readr::read_tsv("../../.my.cnf")$pw,
                      host = "127.0.0.1",
                      port=3307,
                      dbname=db)


joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm %>% 
  write_csv(paste0(path,"GRiP_Pediatric_ADE_Gold_Standard_List_full_joined.csv"))
DBI::dbWriteTable(conn = con,
                  name = "GRiP_Pediatric_ADE_Gold_Standard_List_full_joined",
                  value = joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm,
                  overwrite=T)

DBI::dbDisconnect(con)

tmp <- joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm %>%
  select(Event_name,Drug_name,
         MedDRA_concept_id,
         MedDRA_concept_name,
         MedDRA_concept_class_id,
         ATC_concept_id,
         ATC_concept_name,
         ATC_concept_class_id,
         SNOMED_concept_id,SNOMED_concept_name,SNOMED_concept_class_id,
         RxNorm_concept_id,RxNorm_concept_name,RxNorm_concept_class_id,
         Classification,Grade,
         Control,Level_of_epidemiological_evidence,Population) %>% 
  distinct() 
tmp %>% 
  write_csv(paste0(path,"GRiP_Pediatric_ADE_Gold_Standard_List_minimal_joined.csv"))

tmp <- joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm %>% 
  select(RxNorm_concept_id,SNOMED_concept_id) %>% 
  distinct() %>% 
  drop_na() 
tmp %>% 
  write_csv(paste0(path,"GRiP_Pediatric_ADE_Gold_Standard_RxNorm_SNOMED_concept_id_pairs.csv"))

tmp <- joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm %>% 
  select(ATC_concept_id,MedDRA_concept_id) %>% 
  distinct() %>% 
  drop_na() 
tmp %>% 
  write_csv(paste0(path,"GRiP_Pediatric_ADE_Gold_Standard_ATC_MedDRA_concept_id_pairs.csv"))

tmp <- joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm %>%
  filter(MedDRA_standard_concept=="C") %>% 
  select(RxNorm_concept_id,SNOMED_concept_id) %>% 
  distinct() %>% 
  drop_na() 
tmp %>% 
  write_csv(paste0(path,"GRiP_Pediatric_ADE_Gold_Standard_RxNorm_SNOMED_concept_id_pairs_MedDRA_standard_classification.csv"))

tmp <- joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm %>% 
  filter(MedDRA_standard_concept=="C") %>% 
  select(ATC_concept_id,MedDRA_concept_id) %>% 
  distinct() %>% 
  drop_na() 

tmp %>% 
  write_csv(paste0(path,"GRiP_Pediatric_ADE_Gold_Standard_ATC_MedDRA_concept_id_pairs_MedDRA_standard_classification.csv"))

cols <- colnames(joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm)
joined_MedDRA_ATC_MedDRA_relations_c_SNOMED_relations_c_ATC_relations_RxNorm %>% 
  select(all_of(cols)) %>% 
  select(Event_name,contains("MedDRA")) %>% 
  distinct() %>% 
  arrange(Event_name,MedDRA_concept_class_id,
          MedDRA_concept_code,MedDRA_concept_id) %>% 
  write_csv(paste0(path,"GRiP_Pediatric_ADE_Gold_Standard_Event_MedDRA_vocabulary.csv"))
