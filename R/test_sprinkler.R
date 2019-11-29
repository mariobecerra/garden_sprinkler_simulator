library(ggplot2)
library(here)

# Source sprinkler function
source(here("R/sprinkler.R"))

# Create and save small random design
create_random_design(n_runs = 10, 
                     seed = 2019, 
                     file_out_name = here("dat/random_design.tsv"))

# Run sprinkler from saved tsv file
sprinkler(here("dat/random_design.tsv"))

# Run sprinkler by creating random design
sprinkler(random_matrix_n_runs = 10, 
          random_matrix_seed = 2019)

# Run sprinkler by creating random design and adding noise
sprinkler(random_matrix_n_runs = 10, 
          random_matrix_seed = 2019,
          add_noise = T)





## Run big simulations with and without noise and see the effect on the response variables
big_sim = sprinkler(random_matrix_n_runs = 1000, 
                    random_matrix_seed = 2019)

qplot(big_sim$consumption)
qplot(big_sim$range)
qplot(big_sim$speed)


big_sim_2 = sprinkler(random_matrix_n_runs = 1000, 
                      random_matrix_seed = 2019, 
                      add_noise = T)

qplot(big_sim_2$consumption)
qplot(big_sim_2$range)
qplot(big_sim_2$speed)


