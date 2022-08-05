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
  mutate(logFC = round(logFC, 2)) %>%
  mutate(FDR.P.value = signif(adj.P.Val, 3)) %>%
  mutate(gene_symbol = gsub(" .*$", "", Gene)) %>%
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
      fluidRow(br(),
               # Sidebar panel for inputs #####################################################
               sidebarPanel(
                 # Input button for Gene
                 selectizeInput(
                   "Gene",
                   "Select Gene:",
                   choices = c(""),
                   selected = ""
                 )
               )),
      h2(textOutput("gene_name")),
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
      hr(),
      print("*Displayed values are FDR adjusted p-values obtained from DESeq."),
      br(),
      print("*Refer to following paper for more information:")
    ),
    tabItem(
      tabName = "DESeq_table",
      br(),
      h2("Full Table of DESeq Results"),
      br(),
      DT::dataTableOutput("fulltable")
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

  updateSelectizeInput(
    session,
    "Gene",
    choices = c(sort(names(exprs_data)[2:ncol(exprs_data)])),
    selected = "SLC4A1",
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

  output$exprPlot <- renderPlotly({
    if (!target() == "") {
      gg <-
        qplot(
          Phenotype,
          eval(as.name(target())),
          data = exprs_data,
          fill = Phenotype,
          ylab = NULL
        ) +
        geom_boxplot() +
        facet_grid( ~ Dataset) +
        geom_point(position = position_jitterdodge(0.1)) +
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
      ss <- subset(deseq_df, Gene == target())
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
      deseq_df,
      escape = FALSE,
      options = list(pageLength = 10,
                     autoWidth = TRUE),
      filter = "top"
    )
    full_t
  })
}

# run app ####
shinyApp(ui, server)
