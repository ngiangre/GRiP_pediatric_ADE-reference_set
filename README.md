# GRiP\_pediatric\_ADE-reference\_set

The Global Research in Pediatrics consortium generated an adverse drug event reference set. The citation is:

Osokogu, O.U., Fregonese, F., Ferrajolo, C. et al. Pediatric Drug Safety Signal Detection: A New Drug–Event Reference Set for Performance Testing of Data-Mining Methods and Systems. Drug Saf 38, 207–217 (2015). https://doi.org/10.1007/s40264-015-0265-0

This repository contains a machine-readable curation of that data resource.


## Data pipeline

The pediatric reference adverse event-drug set is embedded within the original article text referenced above and a supplemental word document text in the *docs/word* folder. I've manually translated the reference set into a machine-readable (excel) file containing adverse event-drug associated attributes, such as population affected and level of evidence. The file can be found at:

[`data/GRiP_Pediatric_ADE_Gold_Standard_List.xlsx`](data/GRiP_Pediatric_ADE_Gold_Standard_List.xlsx)

In creating this file, the terms in the reference set were verified using the concept search tool [Athena](http://athena.ohdsi.org/search-terms/terms) from OHSDI. We found that some terms in the original set were outdated or incorrect for correspondance with an adverse event or drug using Athena. While adhering to the original mapping intention of the adverse event or drug term to a concept identifier, we mapped the vocabulary concept identifier to the OMOP-standard concept identifiers. In order to perform the mapping as described below, download the OHDSI vocabulary tables, including the MedDRA and ATC and RxNorm and SNOMED vocabularies, from the download tab [here](https://athena.ohdsi.org/vocabulary/list).

To make feasible the use of this reference set in analyses within pediatric pharmacovigilance studies, an R script was developed that programmatically parses the excel file into a 'long' format, avoiding multiple excel sheets and converting to modular csv files. Use the script as:

`Rscript src/R/GRiP_Pediatric_ADE_Gold_Standard_Processing.R`

To widen the amount of negative controls for comparison (ADEs that have no evidence association), we algorithmically generated negative controls through the pairwise complement of drugs and adverse events in the positive control ADEs. The notebook with the code is found at:

[`ntbks/R/pediatric_reference_pt_ADE_performances_with_generated_negatives.Rmd`](ntbks/R/pediatric_reference_pt_ADE_performances_with_generated_negatives.Rmd)

[`ntbks/R/pediatric_reference_hlt_ADE_performances_with_generated_negatives.Rmd`](`ntbks/R/pediatric_reference_hlt_ADE_performances_with_generated_negatives.Rmd`)

Use RStudio and 'knit' the files to generate the reference set with negative controls.

The resulting machine-readable, comma-separated files are found in [`data/`](data/).

## Contribute

This machine-readable reference set is meant to improve pediatric drug safety studies. If you spot a mistake in the manual curation from the original article or in any step of the pipeline please send a pull request!

## Other References

Pediatric-specific MedDRA adverse event terms can be found [here](https://www.meddra.org/paediatric-and-gender-adverse-event-term-lists). This can be used in conjunction with this machine-readable reference set within analyses.
