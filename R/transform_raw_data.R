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
# # Function to load and process data
# load_and_process_data <- function(file_path, expression_matrix_file, de_results_file) {
#   experiment_design <- fread(file_path) %>%
#     as.data.frame() %>%
#     column_to_rownames(var = "V1")
#
#   expression_matrix <- fread(expression_matrix_file) %>%
#     as.data.frame() %>%
#     column_to_rownames(var = "V1")
#
#   de_results <- fread(de_results_file) %>%
#     as.data.frame() %>%
#     column_to_rownames(var = "V1")
#
#   # Order the expression data and results by ensemble gene ID
#   expression_matrix <- expression_matrix[order(rownames(expression_matrix)), ]
#   de_results <- de_results[rownames(de_results) %in% rownames(expression_matrix), ]
#   de_results <- de_results[order(rownames(de_results)), ]
#
#   # Check that the expression data and DE results are in the same order
#   stopifnot(all(rownames(de_results) == rownames(expression_matrix)))
#
#   # Identify gene symbols
#   mart <- useDataset("hsapiens_gene_ensembl", useMart("ensembl"))
#   genes <- rownames(expression_matrix)
#   gene_list <- getBM(
#     filters = "ensembl_gene_id",
#     attributes = c("ensembl_gene_id", "external_gene_name", "description", "entrezgene_id"),
#     values = genes,
#     mart = mart
#   )
#
#   gene_list <- gene_list[!duplicated(gene_list[, c("ensembl_gene_id", "external_gene_name")], fromLast = TRUE), ]
#
#   # Merge datasets
#   expression_matrix <- merge(expression_matrix, gene_list[, c("ensembl_gene_id", "external_gene_name")],
#                              by.x = "row.names", by.y = "ensembl_gene_id", all.x = TRUE)
#
#   de_results <- merge(de_results, gene_list[, c("ensembl_gene_id", "external_gene_name", "entrezgene_id")],
#                       by.x = "row.names", by.y = "ensembl_gene_id", all.x = TRUE)
#
#   # Rows without gene symbols
#   cat("Rows without gene symbols:", sum(is.na(de_results[, "external_gene_name"])), "\n")
#
#   # Fill in missing genes with ensemble IDs
#   expression_matrix[is.na(expression_matrix[, "external_gene_name"]), "external_gene_name"] <-
#     expression_matrix[is.na(expression_matrix[, "external_gene_name"]), "Row.names"]
#
#   expression_matrix[expression_matrix[, "external_gene_name"] == "", "external_gene_name"] <-
#     expression_matrix[expression_matrix[, "external_gene_name"] == "", "Row.names"]
#
#   de_results[is.na(de_results[, "external_gene_name"]), "external_gene_name"] <-
#     de_results[is.na(de_results[, "external_gene_name"]), "Row.names"]
#
#   de_results[de_results[, "external_gene_name"] == "", "external_gene_name"] <-
#     de_results[de_results[, "external_gene_name"] == "", "Row.names"]
#
#   # Update Duplicate Genes to include Ensemble ID
#   expression_matrix[duplicated(expression_matrix[, "external_gene_name"]), "external_gene_name"] <-
#     paste0(expression_matrix[duplicated(expression_matrix[, "external_gene_name"]), "external_gene_name"], " (", expression_matrix[duplicated(expression_matrix[, "external_gene_name"]), "Row.names"], ")")
#
#   de_results[duplicated(de_results[, "external_gene_name"]), "external_gene_name"] <-
#     paste0(de_results[duplicated(de_results[, "external_gene_name"]), "external_gene_name"], " (", de_results[duplicated(de_results[, "external_gene_name"]), "Row.names"], ")")
#
#   # Update row names
#   rownames(expression_matrix) <- expression_matrix[, "external_gene_name"]
#   rownames(de_results) <- de_results[, "external_gene_name"]
#
#   # Additional processing steps
#   # (Add your additional data processing steps here)
#
#   # Return the processed data
#   return(list(experiment_design = experiment_design,
#               expression_matrix = expression_matrix,
#               de_results = de_results))
# }
#
# # Load and process ALS data
# als_data <- load_and_process_data(
#   "data/Matrices/BBsamples.design.updated.sv1.171subjects.txt",
#   "data/Matrices/BBNormMatrix.txt",
#   "data/Matrices/KCLBrainBank_DE_res.txt"
# )
#
# # Load and process Target ALS data
# target_als_data <- load_and_process_data(
#   "data/Matrices/TargetAlssamples.design.updated.site.sv1.234subjects.txt",
#   "data/Matrices/TargetALSNormMatrix.txt",
#   "data/Matrices/TargetALS_DE_res.txt"
# )
#
# # Combine and save the data
# combined_data <- merge(als_data$expression_matrix, target_als_data$expression_matrix)
# write.csv(combined_data, "data/combinedExpressionData.csv")
#
# # Save the processed data as RDS
# saveRDS(als_data, "data/als_data.rds")
# saveRDS(target_als_data, "data/target_als_data.rds")
