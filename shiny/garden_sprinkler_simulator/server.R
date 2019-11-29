#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source("helpers.R")

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
            text_out = paste0(text_out, paste(s[i,], collapse = ","), "\n")
        }
        
        
        updateTextAreaInput(session, "inText", value = text_out)
    })
    
    observeEvent(input$simulate_button, {
        
        s = read.csv(text = input$inText, header = F, stringsAsFactors = F)
        sprinkler_res = sprinkler(design_matrix = s)
        
        out_sprinkler = sprinkler_res[, c("consumption", "range", "speed")]
         
        output$view = renderTable({out_sprinkler})
        
    })
    
    output$download <- downloadHandler(
        filename = function(){"results.csv"}, 
        content = function(fname){
            write.csv(out_sprinkler, fname, quote = F, row.names = F)
        }
    )
    

})
