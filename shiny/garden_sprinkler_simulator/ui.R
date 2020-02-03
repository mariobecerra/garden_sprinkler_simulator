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
navbarPage(
    "Garden sprinkler",
    
    
    ####################################################
    ####################################################
    ####################################################
    # 1st tab
    ####################################################
    ####################################################
    ####################################################
    tabPanel(
        "Home",
        
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
                
                p("Here is a randomly generated design with 10 runs. The values are separated by tabs. The design you paste should also be separated by tabs."),
                
                
                textAreaInput("inText", 
                              label = NULL,
                              width = "700px",
                              height = "400px")
                
                
            )
        )
    ),
    
    
    ####################################################
    ####################################################
    ####################################################
    # 2nd tab
    ####################################################
    ####################################################
    ####################################################
    tabPanel(
        "Help",
        p("When using a garden sprinkler one of the quality parameters that defines a good sprinkler is a low consumption of water. We are interested in optimizing this response by following the response surface methodology. There are three responses that can be of interest: consumption (minimize), speed (maximize), range (maximize). When building sprinklers, there are 8 design parameters that we can adapt:"),
        
        imageOutput("sprinkler_schematics", height = 350),
        
        p("The extreme limits for the settings can be found in the design configuration table. This means that you cannot go outside of these bounds in the simulator! The real sprinklers are limited to these values by constraints given by the production engineers. If you leave a value out of your design, the simulator offers you three choices to fix this variable at. Always input your design in real units, not coded units!!!"),
        
        p("The columns of your dataframe should be ordered in the same way as the factors are shown in simulator settings in the figure above. If you leave factors out, you just keep the order as given in the design simulator heading (or the table in this text) with these excluded.. A few examples of how the columns should be ordered can be found below."),
        
        h3("Design configuration table"),
        
        p("This table gives the limits extreme limits for the sprinkler settings."),
        
        tableOutput("table_variables"),
        
        h3('Build-up of a .txt data file'),
        p('When using a txt file the simulator expects the following things:'),
        tags$ol(
            tags$li('Column separator is a tab ("\\t")'),
            tags$li('Decimal separator is a point, not a comma (unless changed in the configuration)'),
            tags$li('The columns should not be quoted'),
            tags$li('No column or row headers should be included')),
        p('To write a design to a tsv (tab-separated values) file in R, use the following code:'),
        pre('write.table(design, "folder_name/design.txt", sep = "\\t", quote = FALSE, dec = ".", row.names = FALSE)'),
        p('where', tags$em("design"), 'is the name of the dataframe with the design,', tags$em('folder_name/design.txt'), 'should be replaced with the path where the file is going to be saved.'),
        br(),
        br(),
        br(),
        br()
        
    ),
    
    
    ####################################################
    ####################################################
    ####################################################
    # 3rd tab
    ####################################################
    ####################################################
    ####################################################
    tabPanel(
        "About",
        h1("About this simulation"),
        
        p("This simulation is based on the original code in ", 
           a("Siebertz, K., et al. (2010). Statistische Versuchspanung (1st ed.). Berlin Heidelberg: Springer-Verlag", 
             href = "https://link.springer.com/chapter/10.1007%2F978-3-642-05493-8_2"), 
           "and",
           a("Koen Rutten's web adaptation.", href = "https://twilights.be/sprinkler")
        ),
        
        p("This app was built with ", 
           a("Shiny from RStudio", href = "http://shiny.rstudio.com/"),
           "by",
           a("Mario Becerra", href = "http://mariobecerra.github.com/"),
           "for",
           a("Peter Goos", href = "https://www.kuleuven.be/wieiswie/en/person/00006560"),
           "to use in his classes."
        )
    )
)

