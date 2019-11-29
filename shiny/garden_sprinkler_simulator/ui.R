#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # App title ----
    titlePanel("Garden sprinkler simulator"),
    
    # Sidebar layout with input and output definitions ----
    sidebarLayout(
        
        # Sidebar panel for inputs ----
        sidebarPanel(
            
            # Input: Text for providing a caption ----
            # Note: Changes made to the caption in the textInput control
            # are updated in the output area immediately as you type
            # textInput(inputId = "caption",
            #           label = "Caption:",
            #           value = "Data Summary"),
            
            # radioButtons(inputId = "type_design", 
            #              label = "Paste design or create random design", 
            #              choices = c("Generate random design",
            #                          "Paste design"),
            #              inline = F),
            
            actionButton("generate_button", 
                         label = "Generate another random design"),
            h3(),
            actionButton("simulate_button", 
                         label = "Run simulation"),
            
            tableOutput("view"),
            
            downloadButton("download", 
                           label = "Download result")
            
        ),
        
        # Main panel for displaying outputs ----
        mainPanel(
            
            
            h3("Paste design"),
            
            h6("Here is a randomly generated design with 10 runs. The values are separated by commas. The design you paste should also be separated by commas."),
            
            
            textAreaInput("inText", 
                          label = NULL,
                          width = "700px",
                          height = "400px")
            
            
        )
    )
)
)
