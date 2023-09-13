# library(biomaRt)
# library(ggplot2)
# library(knitr)
# library(rmarkdown)
# library(ggthemes)
# library(plotly)
# library(DT)
# library(data.table)
# library(dplyr)
# library(shinythemes)
# library(RColorBrewer)
# library(markdown)
# library(tibble)
# library(stringr)
#
# ########## ALS data
# bbExperimentDesign <-
#   fread(
#     "data/Matrices/BBsamples.design.updated.sv1.171subjects.txt"
#   ) %>%
#   as.data.frame() %>%
#   column_to_rownames(var = "V1")
#
# bbExpressionMatrix <-
#   fread("data/Matrices/BBNormMatrix.txt") %>%
#   as.data.frame() %>%
#   column_to_rownames(var = "V1")
#
# bbDEResults <-
#   fread("data/Matrices/KCLBrainBank_DE_res.txt") %>%
#   as.data.frame() %>%
#   column_to_rownames(var = "V1")
#
# taExperimentDesign <-
#   fread(
#     "data/Matrices/TargetAlssamples.design.updated.site.sv1.234subjects.txt"
#   ) %>%
#   as.data.frame() %>%
#   column_to_rownames(var = "V1")
#
# taExpressionMatrix <-
#   fread("data/Matrices/TargetALSNormMatrix.txt") %>%
#   as.data.frame() %>%
#   column_to_rownames(var = "V1") %>%
#   select(-V236)
#
# taDEResults <-
#   fread("data/Matrices/TargetALS_DE_res.txt") %>%
#   as.data.frame() %>%
#   column_to_rownames(var = "V1")
#
# # order the expression data and results by ensemble gene ID
# taExpressionMatrix <-
#   taExpressionMatrix[order(rownames(taExpressionMatrix)), ]
#
# taDEResults <-
#   taDEResults[rownames(taDEResults) %in% rownames(taExpressionMatrix), ]
#
# taDEResults <- taDEResults[order(rownames(taDEResults)), ]
#
# bbExpressionMatrix <-
#   bbExpressionMatrix[order(rownames(bbExpressionMatrix)), ]
#
# bbDEResults <- bbDEResults[order(rownames(bbDEResults)), ]
#
# # Check that the expression data and DE results are in the same order
# all(rownames(taDEResults) == rownames(taExpressionMatrix))
# all(rownames(bbExpressionMatrix) == rownames(bbDEResults))
#
# ### Identify gene symbols
# mart <- useDataset("hsapiens_gene_ensembl", useMart("ensembl"))
# genes <- rownames(taExpressionMatrix)
# G_list <-
#   getBM(
#     filters = "ensembl_gene_id",
#     attributes = c(
#       "ensembl_gene_id",
#       "external_gene_name",
#       "description",
#       "entrezgene_id"
#     ),
#     values = genes,
#     mart = mart
#   )
#
# G_list <-
#   G_list[!duplicated(G_list[, c("ensembl_gene_id", "external_gene_name")], fromLast =
#                        T), ]
#
# # Merge datasets
# taExpressionMatrix <-
#   merge(
#     taExpressionMatrix,
#     G_list[, c("ensembl_gene_id", "external_gene_name")],
#     by.x = "row.names" ,
#     by.y = "ensembl_gene_id",
#     all.x = TRUE
#   )
#
# taDEResults <-
#   merge(taDEResults,
#         G_list[, c("ensembl_gene_id", "external_gene_name", "entrezgene_id")],
#         by.x = "row.names" ,
#         by.y = "ensembl_gene_id",
#         all.x = TRUE)
#
# # Rows without gene symbols
# taDEResults[is.na(taDEResults[, "external_gene_name"]), 1]
#
# ### Identify gene symbols
# genes <- row.names(bbExpressionMatrix)
# G_list <-
#   getBM(
#     filters = "ensembl_gene_id",
#     attributes = c(
#       "ensembl_gene_id",
#       "external_gene_name",
#       "description",
#       "entrezgene_id"
#     ),
#     values = genes,
#     mart = mart
#   )
# G_list <-
#   G_list[!duplicated(G_list[, c("ensembl_gene_id", "external_gene_name")], fromLast =
#                        T), ]
#
# # Merge datasets
# bbExpressionMatrix <-
#   merge(
#     bbExpressionMatrix,
#     G_list[, c("ensembl_gene_id", "external_gene_name")],
#     by.x = "row.names" ,
#     by.y = "ensembl_gene_id",
#     all.x = TRUE
#   )
# bbDEResults <-
#   merge(bbDEResults,
#         G_list[, c("ensembl_gene_id", "external_gene_name", "entrezgene_id")],
#         by.x = "row.names" ,
#         by.y = "ensembl_gene_id",
#         all.x = TRUE)
#
# # Identify Cases and Controls
# bbExperimentDesign[bbExperimentDesign[, "Status"] == 1, "Phenotype"] <-
#   " Control"
# bbExperimentDesign[bbExperimentDesign[, "Status"] == 2, "Phenotype"] <-
#   "ALS"
#
# taExperimentDesign[taExperimentDesign[, "Status"] == 1, "Phenotype"] <-
#   " Control"
# taExperimentDesign[taExperimentDesign[, "Status"] == 2, "Phenotype"] <-
#   "ALS"
#
# # Fill in missing genes with ensemble IDs
# bbExpressionMatrix[is.na(bbExpressionMatrix[, "external_gene_name"]), "external_gene_name"] <-
#   bbExpressionMatrix[is.na(bbExpressionMatrix[, "external_gene_name"]), "Row.names"]
# taExpressionMatrix[is.na(taExpressionMatrix[, "external_gene_name"]), "external_gene_name"] <-
#   taExpressionMatrix[is.na(taExpressionMatrix[, "external_gene_name"]), "Row.names"]
# bbExpressionMatrix[bbExpressionMatrix[, "external_gene_name"] == "", "external_gene_name"] <-
#   bbExpressionMatrix[bbExpressionMatrix[, "external_gene_name"] == "", "Row.names"]
# taExpressionMatrix[taExpressionMatrix[, "external_gene_name"] == "", "external_gene_name"] <-
#   taExpressionMatrix[taExpressionMatrix[, "external_gene_name"] == "", "Row.names"]
#
# bbDEResults[is.na(bbDEResults[, "external_gene_name"]), "external_gene_name"] <-
#   bbDEResults[is.na(bbDEResults[, "external_gene_name"]), "Row.names"]
# taDEResults[is.na(taDEResults[, "external_gene_name"]), "external_gene_name"] <-
#   taDEResults[is.na(taDEResults[, "external_gene_name"]), "Row.names"]
# bbDEResults[bbDEResults[, "external_gene_name"] == "", "external_gene_name"] <-
#   bbDEResults[bbDEResults[, "external_gene_name"] == "", "Row.names"]
# taDEResults[taDEResults[, "external_gene_name"] == "", "external_gene_name"] <-
#   taDEResults[taDEResults[, "external_gene_name"] == "", "Row.names"]
#
#
# # Update Duplicate Genes to include Ensemble ID
# taExpressionMatrix[duplicated(taExpressionMatrix[, "external_gene_name"]), "external_gene_name"] <-
#   paste0(taExpressionMatrix[duplicated(taExpressionMatrix[, "external_gene_name"]), "external_gene_name"], " (", taExpressionMatrix[duplicated(taExpressionMatrix[, "external_gene_name"]), "Row.names"], ")")
# bbExpressionMatrix[duplicated(bbExpressionMatrix[, "external_gene_name"]), "external_gene_name"] <-
#   paste0(bbExpressionMatrix[duplicated(bbExpressionMatrix[, "external_gene_name"]), "external_gene_name"], " (", bbExpressionMatrix[duplicated(bbExpressionMatrix[, "external_gene_name"]), "Row.names"], ")")
#
# taDEResults[duplicated(taDEResults[, "external_gene_name"]), "external_gene_name"] <-
#   paste0(taDEResults[duplicated(taDEResults[, "external_gene_name"]), "external_gene_name"], " (", taDEResults[duplicated(taDEResults[, "external_gene_name"]), "Row.names"], ")")
# bbDEResults[duplicated(bbDEResults[, "external_gene_name"]), "external_gene_name"] <-
#   paste0(bbDEResults[duplicated(bbDEResults[, "external_gene_name"]), "external_gene_name"], " (", bbDEResults[duplicated(bbDEResults[, "external_gene_name"]), "Row.names"], ")")
#
# # Update row names
# rownames(bbExpressionMatrix) <-
#   bbExpressionMatrix[, "external_gene_name"]
# rownames(taExpressionMatrix) <-
#   taExpressionMatrix[, "external_gene_name"]
# rownames(taDEResults) <- taDEResults[, "external_gene_name"]
# rownames(bbDEResults) <- bbDEResults[, "external_gene_name"]
#
# bbExpressionMatrix <-
#   bbExpressionMatrix[, tail(head(colnames(bbExpressionMatrix),-1),-1)]
# taExpressionMatrix <-
#   taExpressionMatrix[, tail(head(colnames(taExpressionMatrix),-1),-1)]
#
# # Transpose expression data
# transposedBbExpressionMatrix <- t(bbExpressionMatrix)
# transposedTaExpressionMatrix <- t(taExpressionMatrix)
#
# transposedBbExpressionMatrix <-
#   as.data.frame(transposedBbExpressionMatrix)
# transposedTaExpressionMatrix <-
#   as.data.frame(transposedTaExpressionMatrix)
#
#
# # Add phenotypic data
# transposedBbExpressionMatrix <-
#   transposedBbExpressionMatrix[order(rownames(transposedBbExpressionMatrix)),]
# bbExperimentDesign <-
#   bbExperimentDesign[order(rownames(bbExperimentDesign)),]
#
# transposedTaExpressionMatrix <-
#   transposedTaExpressionMatrix[order(rownames(transposedTaExpressionMatrix)),]
# taExperimentDesign <-
#   taExperimentDesign[order(rownames(taExperimentDesign)),]
#
# colNamestransposedBbExpressionMatrix <-
#   colnames(transposedBbExpressionMatrix)
# colNamestransposedTaExpressionMatrix <-
#   colnames(transposedTaExpressionMatrix)
#
# nrow(transposedBbExpressionMatrix)
# nrow(bbExperimentDesign)
#
# transposedBbExpressionMatrix <-
#   cbind(transposedBbExpressionMatrix, bbExperimentDesign$Phenotype)
# transposedTaExpressionMatrix <-
#   cbind(transposedTaExpressionMatrix, taExperimentDesign$Phenotype)
#
# colnames(transposedBbExpressionMatrix)[ncol(transposedBbExpressionMatrix)] <-
#   "Phenotype"
# colnames(transposedTaExpressionMatrix)[ncol(transposedTaExpressionMatrix)] <-
#   "Phenotype"
#
# ####
#
# transposedBbExpressionMatrix["Dataset"] <-
#   rep("KCL Brain Bank", nrow(transposedBbExpressionMatrix))
# transposedTaExpressionMatrix["Dataset"] <-
#   rep("Target ALS", nrow(transposedTaExpressionMatrix))
#
# transposedBbExpressionMatrix["Tissue"] <-
#   rep("Motor Cortex", nrow(transposedBbExpressionMatrix))
# transposedTaExpressionMatrix["Tissue"] <-
#   rep("Motor Cortex", nrow(transposedTaExpressionMatrix))
#
#
#
# transposedTaExpressionMatrix <-
#   transposedTaExpressionMatrix[, c("Phenotype",
#                                    "Dataset",
#                                    "Tissue",
#                                    colNamestransposedTaExpressionMatrix)]
# transposedBbExpressionMatrix <-
#   transposedBbExpressionMatrix[, c("Phenotype",
#                                    "Dataset",
#                                    "Tissue",
#                                    colNamestransposedBbExpressionMatrix)]
#
# # Save datasets
# #write.csv(transposedBbExpressionMatrix, "data/brainBainExpressionData.csv")
# #write.csv(transposedTaExpressionMatrix, "data/targetAlsExpressionData.csv")
#
# # Load datasets
# #transposedTaExpressionMatrix <- read.csv("data/brainBainExpressionData.csv")
# #transposedBbExpressionMatrix <- read.csv("data/targetAlsExpressionData.csv")
#
# # Update exression datasets to have the same columns
# colnamesToAddToBb <-
#   setdiff(colnames(transposedTaExpressionMatrix),
#           colnames(transposedBbExpressionMatrix))
# colnamesToAddToTa <-
#   setdiff(colnames(transposedBbExpressionMatrix),
#           colnames(transposedTaExpressionMatrix))
#
# transposedTaExpressionMatrix <-
#   as.data.frame(transposedTaExpressionMatrix)
# transposedBbExpressionMatrix <-
#   as.data.frame(transposedBbExpressionMatrix)
#
# transposedTaExpressionMatrix[colnamesToAddToTa] <-
#   rep(NA, nrow(transposedTaExpressionMatrix))
# transposedBbExpressionMatrix[colnamesToAddToBb] <-
#   rep(NA, nrow(transposedBbExpressionMatrix))
#
# # Reorder the columns
# transposedTaExpressionMatrix <-
#   transposedTaExpressionMatrix[, colnames(transposedBbExpressionMatrix)]
#
# # Merge datasets
# combinedExpressionData <-
#   rbind(transposedBbExpressionMatrix, transposedTaExpressionMatrix)
#
# # Save datast
# #write.csv(combinedExpressionData, "data/combinedExpressionData.csv")
#
# # Convert to tibble and save
# combinedExpressionData <- as_tibble(combinedExpressionData)
# saveRDS(combinedExpressionData, "data/combinedExpressionData.rds")
#
# ##### Format Differential Gene Expression ResultS
# head(bbDEResults)
# head(taDEResults)
#
# bbDEResults["Dataset"] <- "KCL Brain Bank"
# taDEResults["Dataset"] <- "Target ALS"
#
# bbDEResults["Tissue"] <- "Motor Cortex"
# taDEResults["Tissue"] <- "Motor Cortex"
#
# colnames(bbDEResults)[which(names(bbDEResults) == "external_gene_name")] <-
#   "Gene"
# colnames(taDEResults)[which(names(taDEResults) == "external_gene_name")] <-
#   "Gene"
#
# colnames(bbDEResults)[which(names(bbDEResults) == "entrezgene_id")] <-
#   "entrez_id"
# colnames(taDEResults)[which(names(taDEResults) == "entrezgene_id")] <-
#   "entrez_id"
#
# colnames(bbDEResults)[which(names(bbDEResults) == "padj")] <-
#   "adj.P.Val"
# colnames(taDEResults)[which(names(taDEResults) == "padj")] <-
#   "adj.P.Val"
#
# colnames(bbDEResults)[which(names(bbDEResults) == "log2FoldChange")] <-
#   "logFC"
# colnames(taDEResults)[which(names(taDEResults) == "log2FoldChange")] <-
#   "logFC"
#
#
# colnames(bbDEResults)[which(names(bbDEResults) == "Row.names")] <-
#   "gene"
# colnames(taDEResults)[which(names(taDEResults) == "Row.names")] <-
#   "gene"
#
# columns <-
#   c("Dataset",
#     "Gene",
#     "Tissue",
#     "gene",
#     "entrez_id",
#     "logFC",
#     "pvalue",
#     "adj.P.Val")
# bbDEResults <- bbDEResults[, columns]
# taDEResults <- taDEResults[, columns]
#
# combinedResults <- rbind(bbDEResults, taDEResults)
#
# head(combinedResults)
#
# # Convert to tibble and save
# combinedResults <- as.data.frame(combinedResults)
#
# combinedResults <- combinedResults %>%
#   mutate(Log_Fold_Change = round(logFC, 3)) %>%
#   mutate(P_Value = signif(pvalue, 3)) %>%
#   mutate(BH_P_Value = signif(adj.P.Val, 3)) %>%
#   mutate(Gene_Symbol = gsub(" .*$", "", Gene)) %>%
#   mutate(
#     Gene_Symbol_URL = paste(
#       '<a href="http://www.genecards.org/cgi-bin/carddisp.pl?gene=',
#       Gene_Symbol,
#       ' "target="_blank"',
#       '">',
#       Gene_Symbol,
#       '</a>',
#       sep = ""
#     )
#   ) %>%
#   mutate(Ensembl_ID = gene) %>%
#   mutate(
#     Ensembl_ID_URL = paste(
#       '<a href="http://www.ensembl.org/id/',
#       Ensembl_ID,
#       ' "target="_blank"',
#       '">',
#       Ensembl_ID,
#       '</a>',
#       sep = ""
#     )
#   ) %>%
#   mutate(Entrez_ID = entrez_id) %>%
#   mutate(
#     Entrez_ID_URL = paste(
#       '<a href="https://www.ncbi.nlm.nih.gov/gene/',
#       entrez_id,
#       ' "target="_blank"',
#       '">',
#       entrez_id,
#       '</a>',
#       sep = ""
#     )
#   ) %>%
#   dplyr::select(
#     Dataset,
#     Gene,
#     Tissue,
#     Gene_Symbol,
#     Gene_Symbol_URL,
#     Entrez_ID,
#     Entrez_ID_URL,
#     Ensembl_ID,
#     Ensembl_ID_URL,
#     Log_Fold_Change,
#     P_Value,
#     BH_P_Value
#   )
#
# rownames(combinedResults) <- seq(nrow(combinedResults))
#
# head(combinedResults)
#
# saveRDS(combinedResults, "data/combinedResults.rds")
#
# combinedResults <- readRDS("data/combinedResults.rds")
# head(combinedResults)
#
# combinedExpressionData <- readRDS("data/combinedExpressionData.rds")
# combinedExpressionData[1:5, 1:5]
#
# combinedExpressionData[combinedExpressionData$Phenotype == "Case", "Phenotype"] <-
#   "ALS"
# combinedExpressionData[combinedExpressionData$Phenotype == "Control", "Phenotype"] <-
#   " Control"
#
# saveRDS(combinedExpressionData, "data/combinedExpressionData1.rds")
