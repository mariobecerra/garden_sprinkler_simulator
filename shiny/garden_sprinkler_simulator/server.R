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
        
        
        if("comma_sep" %in% input$settings) dec_sep = ","
        else dec_sep = "."
        
        s = try(
            read.table(text = input$inText, header = F, stringsAsFactors = F, dec = dec_sep),
            silent = T
        )
        
        if(class(s) == "try-error"){
            out_sprinkler = data.frame(a = "There was an error in the input.")
            names(out_sprinkler) = ""
            sprinkler_res = out_sprinkler
            
            output$text_output <- renderText({ 
                "There is an error in the input."
            })
        } else{
            
            if(ncol(s) != 8){
                err_message = paste("There is an error in the input.", ncol(s), "columns detected. Should be 8.")
                out_sprinkler = data.frame(
                    a = err_message)
                names(out_sprinkler) = ""
                sprinkler_res = out_sprinkler
                
                output$text_output <- renderText({ 
                    err_message
                })
            } else{
                
                output$text_output <- renderText({ 
                    ""
                })
                
                sprinkler_res = try(
                    sprinkler(design_matrix = s, add_noise = ("noise" %in% input$settings)),
                    silent = T
                )
                
                if(class(sprinkler_res) == "try-error"){
                    
                    output$text_output <- renderText({ 
                        sprinkler_res[1]
                    })
                    
                    out_sprinkler = data.frame(a = sprinkler_res[1])
                    names(out_sprinkler) = ""
                    sprinkler_res = out_sprinkler
                    
                } else{
                    out_sprinkler = sprinkler_res[, c("consumption", "range", "speed")]
                }
                
                output$view = renderTable({out_sprinkler})
            }
        }
        
        
        
        
        
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
