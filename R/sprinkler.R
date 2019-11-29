# Der folgende Quellcode ist unter Octave und Matlab lauffähig. Erforderlich ist eine Eingabedatei
# mit dem gewünschten Versuchsplan passend zu der gewählten Kodierung (zum Beispiel -1 bis 1).
# Jede Zeile entspricht einer separaten Berechnung mit der entsprechenden Faktoreneinstellung.
# Der gesamte Versuchsplan wird per Stapelverarbeitung mit einem Aufruf abgearbeitet.

# The following source code is executable under Octave and Matlab. Required is an input file with
# the desired design matching the chosen encoding (for example -1 to 1). Each line corresponds to
# a separate calculation with the corresponding factor setting. The entire experiment plan is
# processed by batch with a call.


create_random_design = function(n_runs = 10, file_out_name = NULL, seed = NULL){
  
  ### Upper and lower imits of variables:
  limits = as.data.frame(matrix(
    c(
      0, 90,
      0, 90,
      2e-6, 4e-6,
      0.1, 0.2,
      0.01, 0.02,
      0.01, 0.02,
      1, 2,
      5, 10
    ), byrow = T, ncol = 2))
  names(limits) = c("min", "max")
  
  # add names of variables
  limits$variable = c("alpha", "beta", "Aq", "d", "mt", "mf", "pin", "dzul")
  
  # reorder columns
  limits = limits[, c(3, 1, 2)]
  
  # design matrix
  out_df = as.data.frame(matrix(rep(NA_real_, 8*n_runs), ncol = 8))
  names(out_df) = c("alpha", "beta", "Aq", "d", "mt", "mf", "pin", "dzul")
  
  if(!is.null(seed)) set.seed(seed)
  for(j in 1:nrow(limits)){
    out_df[, j] = runif(n_runs, limits$min[j], limits$max[j])
  }
  
  if(!is.null(file_out_name)){
    write.table(out_df, file_out_name, quote = T, col.names = F, row.names = F, sep = "\t")
  }
  
  return(out_df)
  
}




sprinkler = function(
  design_matrix_file_name = NULL,  # tsv file with a design matrix. If no filename is provided, a random design will be generated.
  out_file_name = NULL, # tsv filename to write the output of the simulation
  random_matrix_n_runs = 10, # Number of runs in random design. Is overriden if design_matrix_file_name is provided.
  random_matrix_seed = NULL, # Seed for random design.
  add_noise = F # Add noise to the dependant variables?
){
  # Rasensprengerversuch
  # (c) 2002 - 2009
  # Hauptteil: Karl Siebertz
  # Erweiterung: David van Bebber
  
  
  ### Upper and lower imits of variables (not the most elegant way, but it works)
  limits = as.data.frame(matrix(
    c(
      0, 90,
      0, 90,
      2e-6, 4e-6,
      0.1, 0.2,
      0.01, 0.02,
      0.01, 0.02,
      1, 2,
      5, 10
    ), byrow = T, ncol = 2))
  names(limits) = c("min", "max")
  # add names of variables
  limits$variable = c("alpha", "beta", "Aq", "d", "mt", "mf", "pin", "dzul")
  # reorder columns
  limits = limits[, c(3, 1, 2)]
  
  
  
  # Konstanten
  # Constants
  g <- 10
  pi <- 3.141592654
  rho <- 1000
  dynVis <- 1
  kinVis <- dynVis/rho
  MaxFehler <- 0.005
  
  
  dpzulVariante <- 1# 1Basis 2Variation
  sflVariante <- 1# 1Basis 2Variation
  
  # Read design matrix file
  if(!is.null(design_matrix_file_name)){
    s <- read.table(design_matrix_file_name, stringsAsFactors = F)

  } else{
    s <- create_random_design(
      n_runs = random_matrix_n_runs, 
      seed = random_matrix_seed)
  }
  
  kzei = nrow(s)
  
  
  out_df = as.data.frame(s)
  names(out_df) = c("alpha", "beta", "Aq", "d", "mt", "mf", "pin", "dzul")
  
  out_df$consumption = NA_real_
  out_df$range = NA_real_
  out_df$speed = NA_real_
  
  # big loop
  ominc <- 0
  for (j in 1:kzei){
    
    n <- 0;sfl <- 0;qp <- 0
    
    
    # Berechnung der Parameter
    # Calculation of the parameters
    alpha <-  s[j, 1]
    beta <- s[j, 2]
    A <- s[j, 3]
    d <- s[j, 4]
    mt <- s[j, 5]
    mf <- s[j, 6]
    pin <- s[j, 7]
    dzul <- s[j, 8]
    
    pin <- pin * 1e5
    h <- pin * 1e-4
    R <- d/2
    
    sina <- sin(alpha*pi/180)
    cosa <- cos(alpha*pi/180)
    tana <- tan(alpha*pi/180)
    sinb <- sin( beta*pi/180)
    cosb <- cos(beta *pi/180)
    tanb <- tan( beta*pi/180)
    
    # Interpolation gültig für d von 5mm bis 10mm
    # Interpolation valid for d from 5mm to 10mm
    cvzul <- 10^(5.0704 -0.579413*dzul+0.0196432*dzul^2)
    cvzul <- (cvzul*60000^2)
    
    # Startwerte
    # starting values
    m0 <- 2*rho*A*R*2*g*h*cosa*cosb
    n1 <- 0.1*abs(m0-mt)/(mf+5.0e-4)
    omega <- 2*pi*n1
    msoll <- mt+omega*mf
    mdiff <- m0
    va0 <- sqrt(2*pin/rho)
    deltap <-  abs(msoll*omega)/(A*va0) # Verlustleistung Startwert
    dzul <- dzul * 1e-3
    Azul <- pi/4*dzul^2
    if (dpzulVariante == 1){
      dpzul <- cvzul*(A*va0)^2
    } else {
      dpzul <- 0.1*pin
    }
    it <- 0; va <- 0; vr <- 0; m <- m0
    # Durchfluss bei n = 0
    # Flow at n = 0
    if (dpzulVariante == 1){
      qp <-  sqrt(pin/(cvzul+rho/8/A^2))
    } else {
      c <- 128*R*A^2*kinVis/(dzul^2*Azul)
      qp <-  -c/2+sqrt((c/2)^2+8/rho*pin*A^2)
    }
    va <- qp/2/A
    vr <- va
    vrt <-  va*cosb*cosa
    vat <-  vrt
    m <- rho*qp*R*vat
    if(m>mt) {# Haftreibung überschritten? ## Stiction exceeded?
      # Iteration bis zum Momentengleichgewicht
      # Iteration until moment equilibrium
      while (abs(mdiff) > MaxFehler*abs(m)){
        n <- omega/2/pi
        msoll <-  mt+n*mf
        varm <- omega*R
        # Energiebilanz des gesamten Rasensprengers
        # Energy balance of the entire lawn sprinkler
        pen <- pin-deltap-dpzul
        if(pen < 0.01*pin){
          warning('Fehler: pen < 0.01*pin\n')
          warning("pin: ", pin)
          warning("deltap: ", deltap)
          warning("dpzul: ", dpzul)
          warning("msoll: ", msoll)
          warning("m0: ", m0)
          warning("m: ", m)
          warning("mdiff: ", mdiff)
          warning("ominc: ", ominc)
          warning("vr: ", vr)
          warning("varmva: ", varmva)
          va = 0
          break
        }
        va=sqrt(2*pen/rho);
        if(va^2+varm^2*(cosa^2*cosb^2-1) < 0 ){
          warning('Fehler: va^2+varm^2*(cosa^2*cosb^2-1)<0\n');
          va
          vr
          varm
          vak
          break;
        }
        vr = varm*cosa*cosb
        vr = vr+sqrt(va^2+varm^2*(cosa^2*cosb^2-1))
        vrt = vr*cosb*cosa
        vrr = vr*cosa*sinb
        vrv = vr*sina
        vat = vrt-omega*R
        var = vrr
        vav = vrv
        # Kontrolle der Komponentenzerlegung
        # Control of component decomposition
        vak <- sqrt(vat^2+var^2+vav^2)
        m <- 2*rho*vr*A*R*vat
        mdiff <- m-msoll
        ominc <- 0.1*min(abs(mdiff/m),(0.5*pen/pin))
        # variable Schrittweite
        # variable step size
        omega <- omega*(1+ominc)^sign(mdiff)
        qp <- 2*vr*A
        # Verlustleistung in Druck umgerechnet
        # Power loss converted into pressure
        deltap <-  abs(msoll*omega)/qp
        if (dpzulVariante == 1){
          dpzul <-  cvzul*qp^2
        } else {
          vzul <- qp/2/Azul# qp/2 durch einen Arm ## qp/2 through an arm
          Re <- abs(dzul*vzul/kinVis)
          dpzul <-  64/Re*rho/2*R/dzul*vzul^2
        }
        it <- it+1
        # if (it > 10000){
        #   warning('Fehler: it > 10000\n')
        #   warning("it: ", it)
        #   warning("msoll: ", msoll)
        #   warning("mdiff: ", mdiff)
        #   warning("ominc: ", ominc)
        #   warning("alpha: ", alpha)
        #   warning("beta: ", beta)
        #   warning("A: ", A)
        #   warning("d: ", d)
        #   warning("mt: ", mt)
        #   warning("mf: ", mf)
        #   warning("vr: ", vr)
        #   warning("va: ", va)
        #   warning("vrt: ", vrt)
        #   warning("varm: ", varm)
        #   warning("vat: ", vat)
        #   warning("omega: ", omega)
        #   break
        # }
        if (omega < 0.0062 ){
          warning('Fehler: omega < 0.0062\n')
          warning("it: ", it)
          warning("omega: ", omega)
          n <- 0
          break
        }
      } # end while
    } else {
      omega <- 0
      n <- 0
    }
    # Flugbahn
    # trajectory
    dtropf <- sqrt(4*A/pi)
    etaluft <-  1.82e-5
    nyluft <- etaluft/1.25
    v <- va
    z <- 1.0e-3
    sfl <- 0.0
    vh <- va*cosa
    vv <- va*sina
    deltat <- 0.005
    mtr <- pi/6*dtropf^3*rho
    while (z > 0){
      if (va<0.01){
        break
      }
      Re <- va*dtropf/nyluft
      # Abraham, The Physics of Fluids 13, S.2194
      zeta <-  24/Re*(1+0.11*sqrt(Re))^2
      Fwid <-  1.25/2*va^2*pi/4*dtropf^2*zeta
      atr <- Fwid/mtr
      sfl <- sfl+vh*deltat
      z <- z+vv*deltat
      vh <- vh-atr*cosa*deltat
      vv <- vv-g*deltat-atr*sina*deltat
      va <- sqrt(vh^2+vv^2)
      cosa <-  vh/va
      sina <-  vv/va
    } # end while
    if (sflVariante == 1){
      sfl <- sfl
    } else {
      sfl <- sqrt((R+sinb*sfl)^2+(cosb*sfl)^2)
    }
    qp <- 2*vr*A*60000
    pverh <-  deltap/(rho*g*h)
    # Ausgabe
    # output
    Amm2 <- 1000000*A
    dmm <- 1000*d
    mtmm <- mt*1000
    mfmm <- mf*1000
    dzulmm <-  dzul*1e3
    
    if(add_noise){
      qp = qp + rbeta(1, 0.2, 10)
      sfl = sfl + rbeta(1, 0.2, 10)
      n = n + rbeta(1, 0.2, 10)
    }
    
    out_df[j, 9:11] = c(qp, sfl, n)
    
    
  } ## End huge for loop
  
  # Write in file
  if(!is.null(out_file_name)){
    write.table(out_df, quote = F, row.names = F, sep = "\t")
  }
  
  return(out_df)
}

