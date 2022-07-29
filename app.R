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
# fonts https://fontawesome.com/ ####
# final data  ################################################################
exprs_data <- readRDS("./data/gxprs_base_pheno_alt_names.rds")

# raw data  ################################################################
raw_data <- readRDS("./data/gxprs_raw_base_pheno_alt_names_md5.rds")

# raw data niave process: bk, log2, rsn  ################################################################
raw_data_bklogrsn <- readRDS("./data/gxprs_bklog2rsnCombat_347_31431.rds")

# limma results  ################################################################
limma_df <- readRDS("./data/MRC_LBB_Limma.rds")

limma_df_raw <- readRDS("./data/MRC_LBB_Raw_Limma.rds")

# adding html P.Value    adj.P.Val        B  ################################################################
a <- limma_df %>%
    mutate(Experiment = if_else(Experiment == "AD_v_CO","AD vs CO",
                                if_else(Experiment == "AD_v_COAD","AD vs AsympAD",
                                        if_else(Experiment == "COAD_v_CO","AsympAD vs CO","NA")
                                )
    )
    ) %>%
    mutate(logFC = round(logFC, 2)) %>%
    mutate(CI.L = round(CI.L, 2)) %>%
    mutate(CI.R = round(CI.R, 2)) %>%
    mutate(t = round(t, 2)) %>%
    mutate('logFC(95%CI)' = paste(logFC, " (",CI.L,",",CI.R,")",sep = "")) %>%
    mutate(P.Value = signif(P.Value,3)) %>%
    mutate(FDR.P.value = signif(adj.P.Val,3)) %>%
    mutate(B = round(B, 3)) %>%
    mutate(Gene = paste('<a href="http://www.genecards.org/cgi-bin/carddisp.pl?gene=',Gene,'">',Gene,'</a>',sep = "")) %>%
    mutate(entrez_id = paste('<a href="https://www.ncbi.nlm.nih.gov/gene/',entrez_id,'">',entrez_id,'</a>',sep = "")) %>%
    select(Tissue, Experiment, Gene, entrez_id, logFC, CI.L, CI.R, t, P.Value, FDR.P.value, B)

## adding html P.Value    adj.P.Val        B  ################################################################
b <- limma_df_raw %>%
   mutate(Experiment = if_else(Experiment == "AD_v_CO","AD vs CO",
                               if_else(Experiment == "AD_v_COAD","AD vs AsympAD",
                                       if_else(Experiment == "COAD_v_CO","AsympAD vs CO","NA")
                               )
   )
   ) %>%
   mutate(logFC = round(logFC, 2)) %>%
   mutate(CI.L = round(CI.L, 2)) %>%
   mutate(CI.R = round(CI.R, 2)) %>%
   mutate(t = round(t, 2)) %>%
   mutate('logFC(95%CI)' = paste(logFC, " (",CI.L,",",CI.R,")",sep = "")) %>%
   mutate(P.Value = signif(P.Value,3)) %>%
   mutate(FDR.P.value = signif(adj.P.Val,3)) %>%
   mutate(B = round(B, 3)) %>%
   mutate(Gene = paste('<a href="http://www.genecards.org/cgi-bin/carddisp.pl?gene=',Gene,'">',Gene,'</a>',sep = "")) %>%
   mutate(entrez_id = paste('<a href="https://www.ncbi.nlm.nih.gov/gene/',entrez_id,'">',entrez_id,'</a>',sep = "")) %>%
   select(Tissue, Experiment, Gene, entrez_id, logFC, CI.L, CI.R, t, P.Value, FDR.P.value, B)


# UI ####
ui <- dashboardPage(skin = "blue",
    dashboardHeader(
        title = "MRC-LBB Brain Expression Explorer (Patel .et .al 2018)",
        titleWidth = 600
    ),
    ## dashboardSidebar  ####
    dashboardSidebar(
        ## siderbar menu ####
        sidebarMenu(
            menuItem("DE Gene Explorer", tabName = "main_results", icon = icon("fas fa-cubes")),
            menuItem("Limma DE:Full Table", tabName = "limma_table", icon = icon("fas fa-table")),
            menuItem("Raw Data Explorer", tabName = "raw_data", icon = icon("bar-chart-o")),
            menuItem("README", tabName = "readme", icon = icon("fas fa-info"))
        )
    ),
    ## dashboardBody ####
    dashboardBody(
        tabItems(
        tabItem(tabName = "main_results",
        fluidRow(
            br(),
            # Sidebar panel for inputs #####################################################
            sidebarPanel(
                # Input button for Gene
                selectizeInput("Gene", "Select Gene:",
                               selected = "MOSPD3",
                               # all names of genes available
                               c(sort(names(exprs_data)[3:length(names(exprs_data))]))
                )
            ),
            sidebarPanel(
                # Input button for Plot by phenotype or tissue
                selectizeInput("Plot_by", "Plot by Phenotype or TISSUE:",
                               selected = "Phenotype",c("Phenotype","TISSUE"))
            )
        ),
        h2(textOutput("gene_name")),
        box(width = "105%", height = "105%",
            status="primary",
            solidHeader=TRUE,
            title = "boxplots",
            plotlyOutput("exprPlot",
                         width = "100%",
                         height = "400px",
                         inline=TRUE)
            ),
        br(),
        h2("Table of Results"),
        DT::dataTableOutput("table"),
        hr(),
        print("*Displayed values are FDR adjusted p-values obtained from limma."),
        br(),
        print("*Refer to following paper for more information:")
        ),
        tabItem(tabName = "limma_table",
                br(),
                h2("Full Table of Limma Results"),
                br(),
                DT::dataTableOutput("fulltable")
        ),
        tabItem(tabName = "raw_data",
                fluidRow(
                    br(),
                    # Sidebar panel for inputs #####################################################
                    sidebarPanel(
                        # Input button for Gene
                        selectizeInput("Gene_RAW", "Select Gene:",
                                       selected = "TREM2",
                                       # all names of genes available
                                       c(sort(names(raw_data)[5:length(names(raw_data))]))
                        )
                    ),
                    sidebarPanel(
                        # Input button for Plot by phenotype or tissue
                        selectizeInput("Plot_by_raw", "Plot Raw or Transformed:",
                                       selected = "Raw",c("Raw","Transformed"))
                    ),
                    sidebarPanel(
                        # Input button for Plot by phenotype or tissue
                        selectizeInput("Plot_by_raw_pheno_or_tissue", "Plot by Phenotype or TISSUE:",
                                       selected = "Phenotype",c("Phenotype","TISSUE"))
                    )
                ),
                hr(),
                h2(textOutput("gene_name_raw")),
                plotlyOutput("exprPlotRaw",
                             width = "100%",
                             height = "400px",
                             inline=TRUE),
                br(),
                h2("Full Table of Limma Results"),
                DT::dataTableOutput("fulltable_raw")
                ),
        tabItem(tabName = "readme",
                includeMarkdown("./data/README.md")
                )
    )
    )
)

# server ####
server <- function(input, output) {
    # plot main results ################################################################
    ## gene names
    output$gene_name <- renderText(as.name(input$Gene))
    output$gene_name_raw <- renderText(as.name(input$Gene_RAW))
    target <- reactive({
        input$Gene
    })

    # http://www.sthda.com/english/wiki/ggplot2-colors-how-to-change-colors-automatically-and-manually
    output$exprPlot <- renderPlotly({
        cbbPalette <- c( "#D55E00", "#009e73","#E69F00", "#F0E442","#56B4E9",  "#0072B2", "#009e73", "#CC79A7","#000000")

        smooth_method = "loess" ## "loess"
        if (identical(input$Plot_by, "Phenotype")) {
            gg <- qplot(Phenotype,eval(as.name(input$Gene)), data = exprs_data, fill=Phenotype) +
                    #ggplot(data = exprs_data, aes(x=TISSUE, y = eval(as.name(input$Gene)), fill = Phenotype)) +
                geom_boxplot() +
                facet_grid(~ TISSUE) +
                #scale_fill_brewer(palette="Set2") +
                geom_point(position=position_jitterdodge(0.1), aplha=0.1) +
                geom_smooth(method = smooth_method, se=TRUE, aes(group=1, fill=TISSUE)) +
                #labs(x="", y = "Log2(Expression)") +
                scale_fill_manual(values=cbbPalette)
            gg <- gg + theme_tufte()
            p <- ggplotly(gg) %>%
                layout(boxmode = "group",
                       showlegend = FALSE,
                       margin = list(p=5),
                       yaxis = list(title="Log2(Expression)"))
        } else {
            data_to_plot = exprs_data[ , c("Phenotype","TISSUE",paste(input$Gene) )]
            gg <- ggplot(data = data_to_plot, aes(x = TISSUE, y = eval(as.name(input$Gene)),fill = TISSUE)) +
                geom_boxplot() +
                scale_fill_brewer(palette="Dark2") +
                #labs(x="Brain Region", y = "Log2(Expression)") +
                geom_smooth(method = smooth_method, se=TRUE, aes(group=1, fill=TISSUE)) +
                facet_wrap(~Phenotype) +
                theme_tufte() +
                theme(axis.title.x=element_blank(),
                      axis.text.x=element_blank(),
                      axis.ticks.x=element_blank())
            p <- ggplotly(gg) %>%
                layout(boxmode = "group",
                       margin = list(p=5),
                       yaxis = list(title="Log2(Expression)"))
        }
    })

    # plot table main #################################################################
    output$table <- DT::renderDataTable({
        ss <- subset(limma_df, Gene == input$Gene) %>%
            mutate(Experiment = if_else(Experiment == "AD_v_CO","AD v CO",
                                        if_else(Experiment == "AD_v_COAD","AD vs AsympAD",
                                                if_else(Experiment == "COAD_v_CO","AsympAD vs CO","NA")
                                        )
            )
            ) %>%
            mutate(logFC = round(logFC, 2)) %>%
            mutate(CI.L = round(CI.L, 2)) %>%
            mutate(CI.R = round(CI.R, 2)) %>%
            mutate('logFC(95%CI)' = paste(logFC, " (",CI.L,",",CI.R,")",sep = "")) %>%
            mutate(P.Value = signif(P.Value,3)) %>%
            mutate(FDR.P.value = signif(adj.P.Val,3)) %>%
            mutate(B = round(B, 3)) %>%
            mutate(Gene = paste('<a href="http://www.genecards.org/cgi-bin/carddisp.pl?gene=',Gene,'">',Gene,'</a>',sep = "")) %>%
            mutate(entrez_id = paste('<a href="https://www.ncbi.nlm.nih.gov/gene/',entrez_id,'">',entrez_id,'</a>',sep = "")) %>%
            select(Tissue, Experiment, Gene, entrez_id, `logFC(95%CI)`,P.Value,FDR.P.value)

        ## datatable
        ss <- datatable(ss, escape = FALSE,options = list(pageLength = 25))
        ss
    })

    # full limma table #################################################################
    output$fulltable <- DT::renderDataTable({
        full_t <- datatable(a,
                            escape = FALSE,
                            options = list(pageLength = 10,
                                           autoWidth = TRUE),
                            filter = "top")
        full_t
    })

# ALL PROBES full limma table #############################

    output$fulltable_raw <- DT::renderDataTable({
        full_raw_limma <- datatable(b,
                            escape = FALSE,
                            options = list(pageLength = 10,
                                           autoWidth = TRUE),
                            filter = "top")
        full_raw_limma
    })

    # Plot Raw data  #################################################################
    output$exprPlotRaw <- renderPlotly({
        cbbPalette <- c( "#D55E00", "#009e73","#E69F00", "#F0E442","#56B4E9",  "#0072B2", "#009e73", "#CC79A7","#000000")

        smooth_method = "loess" ## "loess"
        if(identical(input$Plot_by_raw, "Raw")){
            if (identical(input$Plot_by_raw_pheno_or_tissue, "Phenotype")) {
                gg <- qplot(Phenotype, eval(as.name(input$Gene_RAW)), data = raw_data, fill=Phenotype) +
                #gg <- ggplot(data = raw_data, aes(x = TISSUE, y = eval(as.name(input$Gene_RAW)), fill = Phenotype)) +
                    geom_boxplot() +
                    facet_grid(~ TISSUE) +
                    geom_point(position=position_jitterdodge(0.1), aplha=0.1) +
                    geom_smooth(method = smooth_method, se=TRUE, aes(group=1, fill=TISSUE)) +
                    labs(x="Phenotype", y = "Raw(Expression)") +
                    scale_fill_manual(values=cbbPalette)
                gg <- gg + theme_tufte()
                    #scale_fill_manual(values=rep(c("palegreen", "paleturquoise", "slateblue1"), 4))
                p <- ggplotly(gg) %>%
                    layout(boxmode = "group",
                           showlegend=FALSE, margin=list(p=5),
                           yaxis = list(title="Raw(Expression)"))
            } else {
                data_to_plot = raw_data[ , c("Phenotype","TISSUE",paste(input$Gene) )]
                gg <- ggplot(data = data_to_plot, aes(x = TISSUE, y = eval(as.name(input$Gene)),fill = TISSUE)) +
                    geom_boxplot() +
                    scale_fill_brewer(palette="Dark2") +
                    labs(x="Brain Region", y = "Raw(Expression)") +
                    geom_smooth(method = smooth_method, se=TRUE, aes(group=1, fill=TISSUE)) +
                    facet_wrap(~Phenotype) + theme_tufte() +
                    theme(axis.title.x=element_blank(),
                          axis.text.x=element_blank(),
                          axis.ticks.x=element_blank())
                p <- ggplotly(gg) %>%
                    layout(boxmode = "group",
                           yaxis = list(title="Raw(Expression)"))
            }
        } else {
            if (identical(input$Plot_by_raw_pheno_or_tissue, "Phenotype")) {
                gg <- qplot(Phenotype, eval(as.name(input$Gene_RAW)), data = raw_data_bklogrsn, fill=Phenotype) +
                #gg <- ggplot(data = raw_data_bklogrsn, aes(x = TISSUE, y = eval(as.name(input$Gene_RAW)), fill = Phenotype)) +
                    geom_boxplot() +
                    facet_grid(~ TISSUE) +
                    geom_point(position=position_jitterdodge(0.1), aplha=0.1) +
                    geom_smooth(method = smooth_method, se=TRUE, aes(group=1, fill=TISSUE)) +
                    labs(x="Phenotype", y = "Log2(expression)") +
                    scale_fill_manual(values=cbbPalette)
                    #scale_fill_manual(values=rep(c("palegreen", "paleturquoise", "slateblue1"), 4))
                gg <- gg + theme_tufte()
                p <- ggplotly(gg) %>%
                    layout(boxmode = "group",
                           showlegend=FALSE, margin=list(p=5),
                           yaxis = list(title="Log2(Expression)"))
            } else {
                data_to_plot = raw_data_bklogrsn[ , c("Phenotype","TISSUE",paste(input$Gene_RAW) )]
                gg <- ggplot(data = data_to_plot, aes(x = TISSUE, y = eval(as.name(input$Gene_RAW)),fill = TISSUE)) +
                    geom_boxplot() +
                    scale_fill_brewer(palette="Dark2") +
                    labs(x="Brain Region", y = "Log2(Expression)") +
                    geom_smooth(method = smooth_method, se=TRUE, aes(group=1, fill=TISSUE)) +
                    facet_wrap(~Phenotype) + theme_tufte() +
                    theme(axis.title.x=element_blank(),
                          axis.text.x=element_blank(),
                          axis.ticks.x=element_blank())
                p <- ggplotly(gg) %>%
                    layout(boxmode = "group",
                           yaxis = list(title="Log2(Expression)"))
            }
        }
    })
    }

# run app ####
shinyApp(ui, server)