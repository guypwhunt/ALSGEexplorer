## app.R #####
library(shiny)
library(ggplot2)
library(shinydashboard)
library(knitr)
library(rmarkdown)
library(ggthemes)
library(plotly)
library(DT)
library(data.table)
library(dplyr)
library(shinythemes)
library(RColorBrewer)
library(markdown)

# final data  ################################################################
exprs_data <- readRDS("./data/combinedExpressionData.rds")

exprs_data$Dataset <- factor(exprs_data$Dataset)

# deseq results  ################################################################
deseq_df <- readRDS("./data/combinedResults.rds")

# adding html P.Value    adj.P.Val        B  ################################################################
deseq_df <- deseq_df %>%
  mutate(logFC = round(logFC, 2)) %>%
  mutate(FDR.P.value = signif(adj.P.Val, 3)) %>%
  mutate(gene_symbol = gsub( " .*$", "", Gene)) %>%
  mutate(
    gene_URL = paste(
      '<a href="http://www.genecards.org/cgi-bin/carddisp.pl?gene=',
      gene_symbol,
      ' "target="_blank"',
      '">',
      gene_symbol,
      '</a>',
      sep = ""
    )
  ) %>%
  mutate(
    entrez_id = paste(
      '<a href="https://www.ncbi.nlm.nih.gov/gene/',
      entrez_id,
      ' "target="_blank"',
      '">',
      entrez_id,
      '</a>',
      sep = ""
    )
  ) %>%
  dplyr::select(Dataset,
                Gene,
                gene_URL,
                entrez_id,
                logFC,
                FDR.P.value)

# UI ####
  # fonts https://fontawesome.com/ ####
  #############
target <- "SLC4A12"

  output$exprPlot <- renderPlotly({
    cbbPalette <-
      c(
        "#D55E00",
        "#009e73",
        "#E69F00",
        "#F0E442",
        "#56B4E9",
        "#0072B2",
        "#009e73",
        "#CC79A7",
        "#000000"
      )

    gg <-
      qplot(Phenotype,
            eval(as.name(target)),
            data = exprs_data,
            fill = Phenotype,
            ylab = NULL) +
      geom_boxplot() +
      facet_grid(~ Dataset) +
      geom_point(position = position_jitterdodge(0.1)) +
      #geom_smooth(method = NULL, na.rm = TRUE, se=TRUE, aes(group=1, fill=Dataset)) +
      scale_fill_manual(values = cbbPalette) +
      ylab("")
    gg <- gg + theme_tufte()
    p <- ggplotly(gg) %>%
      layout(
        showlegend = FALSE,
        margin = list(p = 5),
        yaxis = list(title = "Normalised Gene Expression")
      )
    p
  })

  output$table <- DT::renderDataTable({
    ss <- subset(deseq_df, Gene == target)
    ## datatable
    ss <-
      datatable(ss, escape = FALSE, options = list(pageLength = 25))
    ss
  })

  # full DESeq table #################################################################
  output$fulltable <- DT::renderDataTable({
    full_t <- datatable(
      deseq_df,
      escape = FALSE,
      options = list(pageLength = 10,
                     autoWidth = TRUE),
      filter = "top"
    )
    full_t
  })
