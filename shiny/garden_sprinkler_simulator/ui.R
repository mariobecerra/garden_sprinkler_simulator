#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

tagList(
    tags$head(tags$script(type="text/javascript", src = "code.js")),
    
    navbarPage(
        title = "Garden sprinkler",
        
        
        
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
                    checkboxGroupInput("settings", "Settings:",
                                       c("Add noise" = "noise",
                                         "Use comma as decimal separator" = "comma_sep")),
                    h3(),
                    actionButton("simulate_button", 
                                 label = "Run simulation"),
                    
                    downloadButton("download", 
                                   label = "Download result"),
                    verbatimTextOutput("text_output"),
                    tableOutput("view")
                    
                    
                    
                ),
                
                # Main panel for displaying outputs ----
                mainPanel(
                    
                    
                    h3("Paste design"),
                    
                    p("Here is a randomly generated design with 10 runs. The values are separated by tabs. The design you paste should also be separated by tabs."),
                    
                    p("Variable order: "),
                    
                    
                    p("1. alpha (vertical nozzle angle), 2. beta (tangential nozzle angle), 3. Aq (nozzle profile), 4. d (diameter of sprinkler head), 5. mt (dynamic friction moment), 6. mf (static friction moment), 7. pin (entrance pressure), 8. dzul (diameter flow line)"), 
                    
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
            
            h3("General information"),
            
            p("When using a garden sprinkler one of the quality parameters that defines a good sprinkler is a low consumption of water. We are interested in optimizing this response by following the response surface methodology. There are three responses that can be of interest: consumption (minimize), speed (maximize), range (maximize). When building sprinklers, there are 8 design parameters that we can adapt: vertical nozzle angle (alpha), tangential nozzle angle (beta), nozzle profile (Aq), diameter of sprinkler head (d), dynamic friction moment (mt), static friction moment (mf), entrance pressure (pin), and diameter flow line (dzul). These parameters are shown in the following diagram:"),
            
            imageOutput("sprinkler_schematics", height = 350),
            
            h3("Design configuration table"),
            
            p("This table gives the limits extreme limits for the sprinkler settings."),
            
            tableOutput("table_variables"),
            
            p("The meaning of the values in the table is that you cannot go outside of these bounds in the simulator. The sprinklers are limited to these values by constraints given by the production engineers. If you leave a value out of your design, the simulator will tell you what variable is out of bounds."),
            
            p("The columns of the design you paste should be ordered in the same way as the factors are shown in simulator settings in the figure above."),
            
            h3('Build-up of a .tsv data file'),
            
            p('When using a txt file the simulator expects the following things:'),
            tags$ol(
                tags$li('Column separator is a tab ("\\t")'),
                tags$li('Decimal separator is a point, not a comma (unless changed in the configuration)'),
                tags$li('The columns should not be quoted'),
                tags$li('No column or row headers should be included')),
            p('To write a design to a tsv (tab-separated values) file in R, use the following code:'),
            pre('write.table(design, "folder_name/design.tsv", sep = "\\t", quote = FALSE, dec = ".", row.names = FALSE)'),
            p('where', tags$em("design"), 'is the name of the dataframe with the design,', tags$em('folder_name/design.tsv'), 'should be replaced with the path where the file is going to be saved.'),
            
            h3('Noise addition'),
            
            p("The simulator has the option to add noise to the response variables. This just means that the response variable may change from run to run, even if all the input values are the same."),
            
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
    
)