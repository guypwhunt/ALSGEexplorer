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
deseq_df <- readRDS("./data/combinedResults.rds") %>%
  rename(BH_P_Value = "FDR_P_Value")

display_deseq_df <- dplyr::select(
  deseq_df,
  Dataset,
  Gene,
  Tissue,
  Gene_Symbol_URL,
  Entrez_ID_URL,
  Ensembl_ID_URL,
  Log_Fold_Change,
  P_Value,
  BH_P_Value
)

deseq_df <- dplyr::select(deseq_df,
  Dataset,
  Gene,
  Tissue,
  Gene_Symbol,
  Entrez_ID,
  Ensembl_ID,
  Log_Fold_Change,
  P_Value,
  BH_P_Value
)

# UI ####
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "ALS Gene Expression Explorer (Kabiljo et al., 2023)",
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
                       "DESeq2 Results Table",
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
            height = "600px",
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
      print("*Displayed values are BH adjusted p-values obtained from DESeq2.")
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
    choices = sort(names(exprs_data)[3:ncol(exprs_data)]),
    selected = "MC4R",
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

        filtered_exprs_data <- exprs_data[exprs_data$Dataset %in% datasets(), ]

        validate(
          need(!all(is.na(filtered_exprs_data[,target()])), "The selected Gene was not identified in the selected Dataset(s)."))

          gg <-
            qplot(
              Phenotype,
              eval(as.name(target())),
              data = filtered_exprs_data,
              fill = Phenotype,
              ylab = NULL
            ) +
            geom_boxplot() +
            facet_grid(~ Dataset) +
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
      paste0(target(), "DESeq2Results.csv")
    },
    content = function(file) {
      write.csv(
        subset(deseq_df, Gene == target() & Dataset %in% datasets())
        ,
        file,
        row.names = FALSE
      )
    }
  )

  output$downloadFullTable <- downloadHandler(
    filename = "DESeq2Results.csv",
    content = function(file) {
      write.csv(
        deseq_df
        ,
        file,
        row.names = FALSE
      )
    }
  )
}

# run app ####
shinyApp(ui, server)
