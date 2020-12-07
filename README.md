# GRiP\_pediatric\_ADE-reference\_set

The Global Research in Pediatrics consortium generated an adverse drug event reference set. TThe citation is:

Osokogu, O.U., Fregonese, F., Ferrajolo, C. et al. Pediatric Drug Safety Signal Detection: A New Drug–Event Reference Set for Performance Testing of Data-Mining Methods and Systems. Drug Saf 38, 207–217 (2015). https://doi.org/10.1007/s40264-015-0265-0


## Data pipeline

The adverse event-drug list is embedded in the article and supplemental word documents. I've manually curated the reference with associated attributes, such as population affected and level of evidence, in a machine readable excel format. 

[Athena](http://athena.ohdsi.org/search-terms/terms) from OHSDI was used for concept look up. Download the OHDSI vocabulary tables, including the MedDRA and ATC and RxNorm and SNOMED vocabularies, from the download tab [here](https://athena.ohdsi.org/vocabulary/list).

Importantly, the MedDRA and ATC standardized vocabulary were ensured to map more accurately and to be up to date for each example ADE. The file can be found at:

`data/GRiP_Pediatric_ADE_Gold_Standard_List.xlsx`

To ease the use of this reference set in analyses for validation within pediatric pharmacovigilance studies, a R script was developed that programmatically parses the excel file into a wider format avoiding multiple excel sheets as well as more modular csv files. Use the script:

`src/R/GRiP_Pediatric_ADE_Gold_Standard_Processing.R`

To widen the amount of negative controls for comparison, we algorithmically generated negative controls through the pairwise complement of positive controls. The notebook with the code is found at:

`ntbks/R/pediatric_reference_pt_ADE_performances_with_generated_negatives.Rmd`

`ntbks/R/pediatric_reference_hlt_ADE_performances_with_generated_negatives.Rmd`

## Contribute

This machine readable reference set is meant to promote and improve validation in pediatric drug safety studies. The manual curation probably has errors and annotation could be improved so please send a pull request!

## References

The MedDRA pediartic specific adverse event terms can be found [here](https://www.meddra.org/paediatric-and-gender-adverse-event-term-lists). This can be used in conjunction with this reference set within analyses. 



