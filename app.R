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
library(shinycssloaders)

# final data  ################################################################
exprs_data <- readRDS("./data/combinedExpressionData.rds")

# deseq results  ################################################################
deseq_df <- readRDS("./data/combinedResults.rds")

# adding html P.Value    adj.P.Val        B  ################################################################
deseq_df <- deseq_df %>%
  mutate(Log_Fold_Change = round(logFC, 2)) %>%
  mutate(FDR_P_Value = signif(adj.P.Val, 3)) %>%
  mutate(Gene_Symbol = gsub(" .*$", "", Gene)) %>%
  mutate(
    Gene_Symbol_URL = paste(
      '<a href="http://www.genecards.org/cgi-bin/carddisp.pl?gene=',
      Gene_Symbol,
      ' "target="_blank"',
      '">',
      Gene_Symbol,
      '</a>',
      sep = ""
    )
  ) %>%
  mutate(Entrez_ID = entrez_id) %>%
  mutate(
    Entrez_ID_URL = paste(
      '<a href="https://www.ncbi.nlm.nih.gov/gene/',
      entrez_id,
      ' "target="_blank"',
      '">',
      entrez_id,
      '</a>',
      sep = ""
    )
  ) %>%
  dplyr::select(
    Dataset,
    Gene,
    Gene_Symbol,
    Gene_Symbol_URL,
    Entrez_ID,
    Entrez_ID_URL,
    Log_Fold_Change,
    FDR_P_Value
  )

display_deseq_df <- dplyr::select(
  deseq_df,
  Dataset,
  Gene,
  Gene_Symbol_URL,
  Entrez_ID_URL,
  Log_Fold_Change,
  FDR_P_Value
)

# UI ####
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "ALS Gene Expression Explorer (Kabiljo .et .al 2022)",
                  titleWidth = 600),
  ## dashboardSidebar  ####
  dashboardSidebar(## siderbar menu ####
                   sidebarMenu(
                     menuItem(
                       "Gene Expression Explorer",
                       tabName = "main_results",
                       icon = icon("fas fa-cubes")
                     ),
                     menuItem(
                       "DESeq Results Table",
                       tabName = "DESeq_table",
                       icon = icon("fas fa-table")
                     ),
                     menuItem("README", tabName = "readme", icon = icon("fas fa-info"))
                   )),
  ## dashboardBody ####
  dashboardBody(tabItems(
    tabItem(
      tabName = "main_results",
      fluidRow(
        br(),
        # Sidebar panel for inputs #####################################################
        sidebarPanel(
          # Input button for Gene
          selectizeInput(
            "Gene",
            "Select Gene:",
            choices = c(""),
            selected = ""
          ),
        ),
        sidebarPanel(
          # Input button for Datasets
          selectizeInput(
            "Datasets",
            "Select Dataset(s):",
            choices = c(""),
            selected = "",
            multiple = TRUE
          )
        )
      ),
      box(
        width = "105%",
        height = "105%",
        status = "primary",
        solidHeader = TRUE,
        title = "boxplots",
        withSpinner(
          plotlyOutput(
            "exprPlot",
            width = "100%",
            height = "400px",
            inline = TRUE
          )
        )
      ),
      br(),
      h2("Table of Results"),
      DT::dataTableOutput("table"),
      br(),
      downloadButton("downloadFilteredTable", "Download"),
      br(),
      br(),
      print("*Displayed values are FDR adjusted p-values obtained from DESeq."),
      br(),
      print("*Refer to following paper for more information:")
    ),
    tabItem(
      tabName = "DESeq_table",
      br(),
      h2("Full Table of DESeq Results"),
      br(),
      DT::dataTableOutput("fulltable"),
      br(),
      downloadButton("downloadFullTable", "Download")
    ),
    tabItem(tabName = "readme",
            includeMarkdown("./data/README.md"))
  ))
)

# server ####
server <- function(input, output, session) {
  # fonts https://fontawesome.com/ ####
  #############
  target <- reactive({
    input$Gene
  })

  datasets <- reactive({
    input$Datasets
  })

  updateSelectizeInput(
    session,
    "Gene",
    choices = sort(names(exprs_data)[2:ncol(exprs_data)]),
    selected = "SLC4A1",
    server = TRUE
  )

  datasetNames <- unique(display_deseq_df$Dataset)

  updateSelectizeInput(
    session,
    "Datasets",
    choices = datasetNames,
    selected = datasetNames[1:2],
    server = TRUE
  )

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

  output$exprPlot <-
    renderPlotly({
      if (!target() == "") {
        validate(
          need(datasets(), "Please select a Gene and at least 1 Dataset.")
        )
        gg <-
          qplot(
            Phenotype,
            eval(as.name(target())),
            data = exprs_data[exprs_data$Dataset %in% datasets(), ],
            fill = Phenotype,
            ylab = NULL
          ) +
          geom_boxplot() +
          facet_grid(~ Dataset) +
          #geom_point(position = position_jitterdodge(0.1)) +
          #geom_smooth(method = "loess",
          #            se = TRUE,
          #            aes(group = 1, fill = Dataset)) +
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
      }
    })


  output$table <- DT::renderDataTable({
    if (!target() == "") {
      ss <- subset(display_deseq_df, Gene == target() & Dataset %in% datasets())

      ## datatable
      ss <-
        datatable(ss,
                  escape = FALSE,
                  options = list(pageLength = 25))
      ss
    }
  })


  # full DESeq table #################################################################
  output$fulltable <- DT::renderDataTable({
    full_t <- datatable(
      display_deseq_df,
      escape = FALSE,
      options = list(pageLength = 10,
                     autoWidth = TRUE),
      filter = "top"
    )
    full_t
  })

  output$downloadFilteredTable <- downloadHandler(
    filename = function() {
      paste0(target(), "DESeqResults.csv")
    },
    content = function(file) {
      write.csv(
        subset(deseq_df, Gene == target() & Dataset %in% datasets()) %>%
          dplyr::select(
            Dataset,
            Gene,
            Gene_Symbol,
            Entrez_ID,
            Log_Fold_Change,
            FDR_P_Value
          )
        ,
        file,
        row.names = FALSE
      )
    }
  )

  output$downloadFullTable <- downloadHandler(
    filename = "DESeqResults.csv",
    content = function(file) {
      write.csv(
        dplyr::select(
          deseq_df,
          Dataset,
          Gene,
          Gene_Symbol,
          Entrez_ID,
          Log_Fold_Change,
          FDR_P_Value
        )
        ,
        file,
        row.names = FALSE
      )
    }
  )
}

# run app ####
shinyApp(ui, server)
