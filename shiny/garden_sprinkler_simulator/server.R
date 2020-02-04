#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(stringr)
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
        
        text_out_message = ""
        
        if("comma_sep" %in% input$settings) dec_sep = ","
        else dec_sep = "."
        
        s = try(
            read.table(text = input$inText, header = F, stringsAsFactors = F, dec = dec_sep),
            silent = T
        )
        
        if(class(s) == "try-error"){
            
            
            # If this error message is found, it is because input space is empty
            string_find = "no lines available in input"
            if(grepl(string_find, as.character(s[1]))){
                text_out_message = "Empty input space."
            }
            
            
            out_sprinkler = data.frame(a = text_out_message)
            names(out_sprinkler) = ""
            sprinkler_res = out_sprinkler
            
            output$text_output <- renderText({ 
                text_out_message
            })
            
            # text_out_message = ""
            
        } else{
            
            if(ncol(s) != 8){
                text_out_message = paste(
                    "There is an error in the input.", 
                    ncol(s), 
                    "columns detected. Should be 8.")
                
                out_sprinkler = data.frame(
                    a = text_out_message)
                names(out_sprinkler) = ""
                sprinkler_res = out_sprinkler
                
                output$text_output <- renderText({ 
                    text_out_message
                })
                
                # text_out_message = ""
                
            } else{
                
                output$text_output <- renderText({ 
                    text_out_message
                })
                
                sprinkler_res = try(
                    sprinkler(design_matrix = s, add_noise = ("noise" %in% input$settings)),
                    silent = T
                )
                
                if(class(sprinkler_res) == "try-error"){
                    
                    # text_out_message = as.character(sprinkler_res[1])
                    
                    # If this error message is found, trim it
                    string_find = "The following errors in the input were found:"
                    if(grepl(string_find, as.character(sprinkler_res[1]))){
                        
                        text_out_message = stringr::str_replace_all(
                            sprinkler_res[1], "\n", "")
                        text_out_message = stringr::str_replace_all(
                            text_out_message, "isn't true.", "")
                        text_out_message = stringr::str_replace_all(
                            text_out_message, "( )*(,)+( )+", ", ")
                        text_out_message = stringr::str_replace_all(
                            text_out_message, "Error : ", "")
                        
                        
                        
                        text_out_message = stringr::str_extract(
                            text_out_message, 
                            paste0(string_find, ".*"))
                        
                        text_out_message = stringr::str_replace_all(
                            text_out_message, string_find, "")
                        
                        
                    }
                    
                    output$text_output <- renderText({ 
                        text_out_message
                    })
                    
                    
                    out_sprinkler = data.frame(a = text_out_message)
                    names(out_sprinkler) = ""
                    sprinkler_res = out_sprinkler
                    
                    text_out_message = ""
                    
                } else{
                    out_sprinkler = sprinkler_res[, c("consumption", "range", "speed")]
                    text_out_message = ""
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
