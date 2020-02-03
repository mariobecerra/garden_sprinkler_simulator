#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(testthat)
source("helpers.R")

variables_tsv <- read.table(
    "variables.tsv", 
    header = T, 
    stringsAsFactors = F,
    colClasses = rep("character", 4))

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    
    # Return the requested dataset ----
    # By declaring datasetInput as a reactive expression we ensure
    # that:
    #
    # 1. It is only called when the inputs it depends on changes
    # 2. The computation and result are shared by all the callers,
    #    i.e. it only executes a single time
    # datasetInput <- reactive({
    #     switch(input$dataset,
    #            "rock" = rock,
    #            "pressure" = pressure,
    #            "cars" = cars)
    # })
    
    
    
    observe({
        generate = input$generate_button
        s = create_random_design(truncate_digits = 8,
                                 n_runs = 10)
        text_out = ""
        
        for(i in 1:nrow(s)){
            text_out = paste0(text_out, paste(s[i,], collapse = "\t"), "\n")
        }
        
        
        updateTextAreaInput(session, "inText", value = text_out)
    })
    
    observeEvent(input$simulate_button, {
        
        s = read.table(text = input$inText, header = F, stringsAsFactors = F)
        sprinkler_res = sprinkler(design_matrix = s)
        
        out_sprinkler = sprinkler_res[, c("consumption", "range", "speed")]
        
        output$view = renderTable({out_sprinkler})
        
        # workaround to download tsv file
        write.table(sprinkler_res, "results_temp.tsv", quote = F, row.names = F)
        
    })
    
    output$download <- downloadHandler(
        filename = function(){"results.tsv"}, 
        content = function(fname){
            # write.csv(sprinkler_res, fname, quote = F, row.names = F)
            file.copy("results_temp.tsv", fname)
            file.remove("results_temp.tsv")
        }
    )
    
    
    output$sprinkler_schematics <- renderImage({
        
        return(list(
            src = "sprinklerschematics.png",
            contentType = "image/png",
            alt = "Sprinkler"
        ))
    }, deleteFile = F)
    
    output$table_variables  <- renderTable(variables_tsv)
    
    
})
