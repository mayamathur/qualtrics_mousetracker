
# Contact: Maya Mathur (mmathur@stanford.edu)

############################### RESHAPE WIDE TO LONG ###############################

# for analysis, we want a long-form dataset with n.faces rows per subject
# each row represents one unique face and subject combo

# dat: wide-format data
# stim.names: vector of stimulus names
wide_to_long = function( dat,
                         stim.names ) {
  # new id variable
  dat$id = 1:nrow(dat)
  
  ( cat.names = names(dat)[ grep( "_cat", names(dat) ) ] )
  ( xflips.names = names(dat)[ grep( "xflips", names(dat) ) ] )
  ( max.x.dev.names = names(dat)[ grep( "max.x.dev", names(dat) ) ] )
  ( area.names = names(dat)[ grep( "area", names(dat) ) ] )
  ( speed.names = names(dat)[ grep( "speed", names(dat) ) ] )
  ( rxnt.names = names(dat)[ grep( "rxnt", names(dat) ) ] )
  
  # reshape wide to long
  # https://stackoverflow.com/questions/12466493/reshaping-multiple-sets-of-measurement-columns-wide-format-into-single-columns
  library(car)
  l = reshape( dat, varying = list(
    Cat = cat.names,
    XFlips = xflips.names,
    MaxXDev = max.x.dev.names,
    Area = area.names,
    Speed = speed.names,
    RXNT = rxnt.names
  ),
  v.names=c(
    "cat",
    "xflips",
    "xdev",
    "area",
    "speed",
    "rxnt"
  ),
  idvar="ResponseId",
  times = stim.names,
  direction="long" )
  
  names(l)[ names(l) == "time" ] = "stim.name"
  
  return(l)
}


############################### ADD OUTCOMES TO WIDE DATA ###############################

# adds outcome variables to wide-format data

# dat: wide-format data
# xl: subject-trial list of x-coordinates produced by make_subject_lists
# yl: subject-trial list of y-coordinates produced by make_subject_lists
# tl: subject-trial list of times produced by make_subject_lists

add_outcomes = function( dat, 
                         xl, 
                         yl, 
                         tl ) {
  
  # number of stimuli
  n.stim = length(xl[[1]])
  
  ##### X-flips ##### 
  xflips.list = lapply( xl, 
                        FUN = function(subj.list) {
                          lapply( subj.list, xflips )
                        }
  )
  
  # turn into dataframe
  res = list_to_df( list = xflips.list, 
                    prefix = "xflips", 
                    n.stim = n.stim )
  dat = cbind(dat, res)
  
  
  ##### Max X-Deviation from Ideal ##### 
  max.x.dev.list = mapply( 
    FUN = function(subj.xl.list, subj.yl.list) {
      mapply( FUN = function(x,y) max_x_dev(x,y),
              subj.xl.list, 
              subj.yl.list )
    }, 
    xl,
    yl
  )
  
  # this one is not a list, so not using the list_to_df fn
  max.x.dev.list = as.data.frame( t(max.x.dev.list) )
  names(max.x.dev.list) = paste( "max.x.dev.face.", 1:n.stim, sep="" )
  dat = cbind(dat, max.x.dev.list)
  
  ##### Area Vs. Ideal ##### 
  area.list = mapply( 
    FUN = function(subj.xl.list, subj.yl.list) {
      mapply( FUN = function(x,y) area_vs_ideal(x,y),
              subj.xl.list, 
              subj.yl.list )
    }, 
    xl,
    yl
  )

  # turn into dataframe
  area.list = as.data.frame( t(area.list) )
  names(area.list) = paste( "area.face.", 1:n.stim, sep="" )
  dat = cbind(dat, area.list)
  
  ##### Peak Speed ##### 
  speed.list = mapply( 
    FUN = function(subj.xl.list, subj.t.list) {

      mapply( FUN = function(x,y) peak_speed(x,y),
              subj.xl.list,
              subj.t.list )
    }, 
    xl,
    tl
  )

  # turn into dataframe
  speed.list = as.data.frame( t(speed.list) )
  names(speed.list) = paste( "speed.face.", 1:n.stim, sep="" )
  dat = cbind(dat, speed.list)
  
  ##### Reaction Time ##### 
  rxnt.list = lapply( tl, 
                      FUN = function(subj.list) {
                        lapply( subj.list,
                                FUN = function(vec) vec[ length(vec) ] - vec[1] )
                      }
  )
  
  # turn into dataframe
  res = list_to_df( list = rxnt.list, 
                    prefix = "rxnt",
                    n.stim = n.stim )
  dat = cbind(dat, res)
  
  invisible(dat)
}


############################### ANALYZE ALERTS ###############################

# returns alerts by subject (al list)
#  and the strings for each trial
# and prints out summary stats about alerts

# dat: wide-format data
# n.stim: number of real experimental stimuli
# key: stimulus name and URL key produced by make_url_key

describe_alerts = function( dat,
                            n.stim,
                            key ) {
  
  # urls in as-presented (randomized) order
  urll = lapply( 1:nrow(dat),
                 FUN = function(id){
                   split_on_char( dat,
                                  var.name = "stimulusOrder", 
                                  id = id,
                                  split.char = "\\|",
                                  as.numeric = FALSE )
                 } ) 
  
  
  # alerts also in as-presented order
  al = lapply( 1:nrow(dat),
               FUN = function(id){
                 split_on_char( dat,
                                var.name = "alerts",
                                id = id )
               } ) 
  
  # reorder the alerts
  al = lapply( 1:length(al), 
               FUN = function(id) {
                 reorder_random_thing( randomized.urls = urll[[id]],
                                       key.urls = key$url,
                                       al[[id]] )
               } )
  
  ##### Total Alerts Received by Subject #####
  # number of alerts in each trial
  alert.strs = unlist(al)
  n.trials =  nrow(dat) * n.stim
  n.alerts = rep( 0, n.trials )
  n.alerts[ alert.strs != 0 ] = nchar( alert.strs[ alert.strs != 0 ] )
  
  cat("\n\nTotal number of alerts received (proportion of subjects):\n")
  print( prop.table( table( n.alerts ) ) )
  
  ##### Individual Alerts by Trial #####
  # separate them into individual alerts (instead of trials)
  alerts = as.numeric( unlist( strsplit( as.character(alert.strs), split = "") ) )

  # recode them for clarity
  library(car)
  alerts = recode( alerts, 
                   "0 = 'None';
                   1 = 'Started too early';
                   2 = 'Started too late';
                   3 = 'Surpassed trial time limit';
                   4 = 'Window too small' " )
  
  cat("\n\nProportion of trials receiving each type of alert:\n")
  print( prop.table( table(alerts) ) )
  
  ##### Number of Subjects Ever Receiving Each Alert #####
  ever.alerts = vapply( c("1", "2", "3", "4"),
                        function(x) length( grep( x, dat$alerts ) ) / nrow(dat),
                        FUN.VALUE = -99 )
  
  names(ever.alerts) = recode( names(ever.alerts), 
                               "0 = 'None';
                               1 = 'Started too early';
                               2 = 'Started too late';
                               3 = 'Surpassed trial time limit';
                               4 = 'Window too small' " )
  
  cat("\n\nProportion of subjects ever receiving each type of alert:\n")
  print( ever.alerts )
  
  # return al because it's useful
  # also return alerts
  invisible( list(alerts.by.subject = al,
                  n.alerts.by.trial = n.alerts,
                  alerts.by.trial = alerts,
                  ever.alerts = ever.alerts) )
  
}



############################### MAKE URL KEY FOR RANDOM LOOP AND MERGE ###############################

# makes a .csv file linking the stimulus URLs
# to their names
# does this by using Qualtrics' special extra header rows

# dat: wide-format data
# n.stim: number of real experimental stimuli
# stim.names: vector of stimulus names
# lm.varname: the name given to the experimental Loop & Merge block in Qualtrics
#  (i.e., it is "cat" in the default Qualtrics template)
# key.dir: where to save the .csv key file

make_url_key = function( dat,
                         n.stim, 
                         stim.names, 
                         lm.varname, 
                         key.dir ) {
  
  # Qualtrics puts the Loop & Merge iterate (e.g., the URL for an image) in the first row
  # exploit this to see which face is being called "face 1", etc.
  
  # grab columns with radio button decisions for each LM stimulus in nonrandom order
  # the "_" is because Qualtrics names the variables "1_cat", etc.
  cols = grep( paste( "_", lm.varname, sep = "" ), names(dat) ) 
  
  # check for missing data in these columns
  # which could occur if using Loop & Merge over only a subset of stimuli
  # or allowing subjects to skip questions
  if( any( is.na( d[ , cols] ) ) ) stop("Some category decision data are missing. You will need to modify the R code in order to proceed.")
  
  # calling it "URLs" since we are mainly considering cases where the 
  #  LM iterates are images with URLs from Qualtrics graphics library
  ordered.urls = vapply( dat[1, cols], as.character, "asdf")  # this version works for csv files
  
  # remove the extra " - XX_cat" string from each URL
  ( ordered.urls = as.vector( vapply( ordered.urls,
                                      function(x) strsplit(x, " ")[[1]][1],
                                      FUN.VALUE = "blahblah" ) ) )
  # make key
  face.names = paste("face.", 1:n.stim, sep="")
  ( key = data.frame( stim.name = stim.names,
                      url = ordered.urls ) )
  setwd(key.dir)
  write.csv(key, "autogenerated_stimulus_vs_url_key.csv", row.names = FALSE )
}



############################### REORDER RANDOMIZED VECTOR ###############################

# works for a list or vector

# randomized.urls: vector of urls in as-presented (randomized) order
# key.urls: vector of urls in "correct" order (to which x will be reordered)
# x: randomized vector or list to reorder (e.g., alerts)

reorder_random_thing = function( randomized.urls, 
                                 key.urls,
                                 x ) {  
  
  # accommodate multiple blocks of trials
  # if survey is set up that way, with different stimuli
  #  in each block, then key.urls will be longer than randomized.urls
  #  so we need to keep only the ones with matches
  key.urls = key.urls[ key.urls %in% randomized.urls ]
  
  library(plyr)
  inds = vapply( as.character(key.urls), 
                 function(i) which( randomized.urls == as.character(i) ),
                 FUN.VALUE = -99 )
  
  # sanity check: should all be TRUE
  # randomized.urls[inds] == key.urls
  x[inds]
}

# # example with vector
# key.urls = c("a", "b", "c")
# randomized.urls = c("c", "a", "b")
# randomized.x = c(3, 1, 2)
# # should be 1, 2, 3
# reorder_random_thing( randomized.urls, key.urls, randomized.x)
# 
# # example with list
# randomized.x = list(3, 1, 2)
# reorder_random_thing( randomized.urls, key.urls, randomized.x)


############################### SPLIT VECTOR ON CHARACTER ###############################

# split string into numeric vector, splitting by a character

# data: wide-format data
# var.name: quoted name of variable to split
# split.char: quoted character on which to split
# id: row number to split
# as.numeric: is the resulting vector supposed to be numeric?

split_on_char = function(data,
                         var.name,
                         split.char = "a",
                         id,
                         as.numeric = TRUE ) {
  
  vec = strsplit( as.character(data[[var.name]][id]), split.char )[[1]]
  
  if ( as.numeric == TRUE ) return( as.numeric(vec) )
  else return(vec)
}


############################### SPLIT VECTOR ON CHARACTER ###############################

# split a chosen variable into n.faces vectors by face
# returns a list with n.faces elements for a given subject
# also checks for bad data and expects a global variable, exclusions, 
#  to which we can add bad data info

# data: wide-format data
# var.name: quoted name of variable to split
# id: row number to split
# split.char: quoted character on which to split
# reorder: do we need to reorder the vector because the stimulus presentation 
#  order was randomized?
# key: stimulus/URL key (cannot be NA if reorder == TRUE)

split_on_face = function( data,
                          var.name,
                          id,
                          split.char = "a",
                          reorder = FALSE, 
                          key = NA ) {
  
  # correctly ordered URLs
  key.urls = key$url
  
  # identify face ids to which this subject responded
  temp.names = names(data)[ grep( "_cat", names(data) ) ]
  
  ##### Prepare Times Needed for Splitting #####
  
  # these have length = n.faces
  # time at which page was fully loaded (beginning time for each trial)
  onReadyTime = split_on_char(data = data,
                              var.name = "onReadyTime",
                              id = id )
  
  # time at which subject answered question (ending time for each trial)
  buttonClickTime = split_on_char(data = data,
                                  var.name = "buttonClickTime",
                                  id = id )
  
  
  # current time that goes with position readings
  # length = length(x)
  t = split_on_char(data = data,
                    var.name = "time",
                    id = id )
  
  # check for subjects with bad data
  cant.be.na = c( onReadyTime, buttonClickTime, t, data[[var.name]][id] )
  if ( any( is.na( cant.be.na ) ) ) {
    warning( "ResponseId ", data$ResponseId[id], " should be excluded. Idiosyncratic timing issues caused missing times or outcome variable data.")
    # look for global variable that is tracking subjects to exclude
    if ( exists("exclusions") ) exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[id],
                                                                            reason = "Idiosyncratic timing issues caused missing times or outcome variable data.") )
    return(NA)
    }
  
  if ( max(onReadyTime) > max(t) ) {
    warning( "ResponseId ", data$ResponseId[id], " should be excluded. Continuous timing stopped prematurely.")
    # look for global variable that is tracking subjects to exclude
    if ( exists("exclusions") ) exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[id],
                                                                              reason = "Idiosyncratic timing issues caused missing times or outcome variable data.") )
    return(NA)
    }
  

  # standardize times (convert to seconds since first page loaded)
  origin.time = min(onReadyTime)
  t = (t - origin.time)/1000  
  onReadyTime = (onReadyTime - origin.time) / 1000
  buttonClickTime = (buttonClickTime - origin.time) / 1000
  
  
  # convert string to vector (not yet split on face)
  vec = split_on_char(data = data,
                      var.name = var.name,
                      id = id )
  
  
  # split vec by face
  n.faces = length(onReadyTime)

  # list with n.faces elements
  list = lapply( 1:n.faces,
                 FUN = function(i) {
                   # index first time that's after the onReadyTime
                   start.ind = which( t > onReadyTime[i] )[1]
                   
                   # index of last time that's before thebuttonClickTime
                   end.ind = which(t <buttonClickTime[i])[ length(which(t <buttonClickTime[i])) ]
                   
                   if ( any( buttonClickTime < 0 ) | any( onReadyTime < 0 ) ){ 
                     warning( "ResponseId ", data$ResponseId[id], " should be excluded. One or more button click or on-ready times were negative.")
                     # look for global variable that is tracking subjects to exclude
                     if ( exists("exclusions") ) exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[id],
                                                                                               reason = "Idiosyncratic timing issues caused missing times or outcome variable data.") )
                     return(NA)
                     }
                   
                   if ( any( diff(buttonClickTime) < 0 ) | any( diff(onReadyTime) < 0 ) ){ 
                     warning( "ResponseId ", data$ResponseId[id], " should be excluded. Non-monotonic button click or on-ready times.")
                     # look for global variable that is tracking subjects to exclude
                     if ( exists("exclusions") ) exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[id],
                                                                                               reason = "Idiosyncratic timing issues caused missing times or outcome variable data.") )
                     return(NA)
                     }
                   
                   if( length(buttonClickTime[i]) == 0 ) browser()
                   
                   # vectors for just this face
                   if ( !is.na(buttonClickTime[i]) ) {
                     
                     # if we couldn't retrieve a valid start and end time for this face
                     if ( length(start.ind) == 0 | length(end.ind) == 0 ) {
                       
                       warning( "ResponseId ", data$ResponseId[id], " should be excluded. No valid times within a certain button click/on ready interval.")
                       # look for global variable that is tracking subjects to exclude
                       if ( exists("exclusions") ) exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[id],
                                                                                                 reason = "Idiosyncratic timing issues caused missing times or outcome variable data.") )
                       return(NA)
                       }
                     
                     vec2 = vec[ start.ind : end.ind ]
                   } else {
                     # this happens if they never clicked a radio button for this trial
                     #  because they didn't beat the time limit
                     vec2 = NA
                   }
                   
                 } )
  
  # reorder the sub-lists (1 per face) if order was randomized
  if ( reorder == TRUE & !is.na(key.urls[1]) ) {
    
    randomized.urls = split_on_char( data,
                                     var.name = "stimulusOrder",
                                     id = id,
                                     split.char = "\\|",
                                     as.numeric = FALSE )
    # check for bad data
    if ( any( randomized.urls == "" ) ) {
      warning( "ResponseId ", data$ResponseId[id], " should be excluded. Idiosyncratic issues caused a failure to record one or more stimulus URLs.")
      # look for global variable that is tracking subjects to exclude
      if ( exists("exclusions") ) exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[id],
                                                                                reason = "Idiosyncratic timing issues caused missing times or outcome variable data.") )
      return(NA)
      }
    
    list = reorder_random_thing( randomized.urls = randomized.urls, 
                                 key.urls = key.urls,
                                 x = list )
    
  }
  
  if ( reorder == TRUE & is.na(key.urls[1]) ) {
    stop("Must provide key for reordering the random vector")
  }
  
  return(list)
}



############################### MAKE SUBJECT/TRIAL LISTS ###############################

# for a chosen variable, returns a list of lists
# there is 1 list per subject
# and each list has length equal to number of stimuli,
#  containing a vector of the variable values for that face

# also checks for bad data and expects a global variable, exclusions, 
#  to which we can add bad data info

# data: wide-format data
# var.name: quoted name of variable to split
# reorder: do we need to reorder the vector because the stimulus presentation 
#  order was randomized?
# key: stimulus/URL key (cannot be NA if reorder == TRUE)
# rescale: TRUE/FALSE for whether to rescale the trajectory to have length 1
#  and to start at 0

get_subject_lists = function( data,
                              var.name,
                              reorder = FALSE,
                              key = NA,
                              rescale = FALSE ) {
  
  list = lapply( 1:nrow(data),
                 FUN = function(id){
                   split_on_face( data,
                                  var.name = var.name,
                                  id = id,
                                  reorder = reorder,
                                  key = key )
                 } ) 
  

  ###### Check for too few entries in lists ######
  # number of entries for each subject and trial (1 list per subject)
  n.entries = lapply( list, FUN = function(sublist) unlist( lapply( sublist, FUN=length ) ) )
  
  # minimum entries across stimuli for each subject
  mins = lapply( n.entries, FUN = function(sublist) min(sublist) )
  
  if ( any( mins < 5 ) ) {
    # rows with fewer than 5 entries
    bad.rows = which(mins < 5)
    
    for ( j in bad.rows) {
      warning( "ResponseId(s) ", data$ResponseId[j], " should be excluded for having implausibly few (<5) coordinate or time entries for some stimuli.")
      if ( exists("exclusions") ) exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[j],
                                                                                reason = "Implausibly few (<5) coordinate or time entries for some stimuli." ) )
    }
  }
  
  if ( rescale == TRUE ) {
    
    # absolute difference list (end - start)
    # abs because they could move to either ending button
    dl = lapply( list, function(subj.list)
      lapply( subj.list, function(face.list)
        abs( face.list[[ length(face.list) ]] - face.list[[ 1 ]] ) ) )
    
    # rescale so every subject covers distance of 1 unit
    for ( i in 1:length(list) ) {
      for ( j in 1:length(list[[i]]) ) {
        
        # check whether subject zoomed
        if ( var.name == "xPos" ) {
          
         # distance between first and last entry of subject i, face j vector
          x.dist = abs( list[[i]][[j]][[length(list[[i]][[j]])]] - list[[i]][[j]][[1]] )
          
          # hard-coded because these are the standard pixel dimensions of experiment
           #min = 243 - 50  # in initial paper submission results (with buffer and less precise coordinate measurements)
           #max = 322 + 50
          min = 235
          max = 335
          
          # check for non-standard pixel dimensions
          if ( x.dist < min | x.dist > max ) {
            warning( "ResponseId(s) ", data$ResponseId[i], " had a nonstandard pixel dimensions.")
            
            exclusions <<- rbind( exclusions, data.frame( ResponseId = data$ResponseId[i],
                                                                                           reason = "Nonstandard pixel dimensions." ) )
          }
        }

        # suppress warnings about longer object not being multiple of shorter one
        list[[i]][[j]] = suppressWarnings( ( list[[i]][[j]] - list[[i]][[j]][[1]] ) / dl[[i]][[j]] )
        
        }
    }
  
    # compensate for the fact that y is measured from upper left of screen
    # swap it so ending position is 1 instead of -1
    if ( var.name == "yPos" ) list = lapply( list, function(l) lapply(l, abs) )
    
  }
  
  return(list)
}


############################### CONVERT A LIST TO A DATAFRAME ###############################

# converts a list to a wide-format dataframe
# to be appended to raw Qualtrics data

# list: the list to be converted
# prefix: variable name prefix when adding the data to Qualtrics dataset
# n.stim: number of stimuli (=number of columns in returned df)

list_to_df = function( list,
                       prefix,
                       n.stim ) {
  
  res = do.call(rbind, list)
  
  # columns are still lists
  res = as.data.frame( apply( res, 2, unlist ) )
  names(res) = paste( prefix, ".face.", 1:n.stim, sep="" )
  return(res)
}



############################### FUNCTIONS FOR COMPUTING OUTCOME VARIABLES ###############################


xflips = function(x) {
  if ( any(is.na(x)) ) return(NA)
  
  # signed change in x-coordinate between each pair
  change.in.x = diff(x)[ !diff(x) == 0 ]
  
  # in which direction did x change?
  change.direction = sign( change.in.x )
  
  # we get an x-flip when there's a change in the change in direction
  sum( diff(change.direction) != 0 )
}



# returns a vector of same length as x, but straight line from start to end point
# the returned vector is the ideal x-coordinates
ideal_traj = function(x, y) {
  if ( any(is.na(x)) ) return(NA)
  #browser()
  start = x[1]
  end = x[ length(x) ]
  
  # average change in x per unit y
  jump.size.per.y = ( end - start ) / ( y[ length(y) ] - y[1] )
  
  # linearly add jumps to the start position
  ideal = start + jump.size.per.y * ( y - y[1] )
  return(ideal)
}


# max absolute horizontal deviation from ideal trajectory
max_x_dev = function(x, t) {
  if ( any( is.na(x) ) ) return(NA)
  ideal = ideal_traj(x, t)
  
  if (length(x) != length(ideal)) stop()
  max( abs(x - ideal) )
}

# area between actual and ideal (Riemann sum)
area_vs_ideal = function(x, y) {
  if ( any( is.na(x) ) ) return(NA)
  ideal = ideal_traj(x, y)
  
  # take middle point of each pair of actual x-values
  temp = cbind( c(x,NA), c(NA,x) )
  xmean = rowMeans(temp)[ -c(1, length( rowMeans(temp) ) ) ]
  
  # take middle point of each pair of ideal x-values
  temp = cbind( c(ideal,NA), c(NA,ideal) )
  idealmean = rowMeans(temp)[ -c(1, length( rowMeans(temp) ) ) ]
  
  # absolute differences between middle of x for each time interval and ideal
  width = abs( xmean - idealmean )
  
  # y-differences
  height = abs( diff(y) )
  
  sum(height*width)
}

# plot the observed trajectory vs. ideal one
plot_vs_ideal = function(x,
                         y,
                         title = NA) {
  
  if ( any( is.na(x) ) ) return(NA)
  ideal = ideal_traj(x, y)
  
  # compare ideal to actual trajectory (ideal in red)
  library(ggplot2)
  p = ggplot( data.frame(x, y), aes(x = x, y = y) ) +
    geom_point() +
    scale_y_continuous( limits = c( 0, 1 ) ) +
    scale_x_continuous( limits = c( -1, 1 ) ) +
    xlab("X-position (std.)") +
    ylab("Y-position (std.)") +
    geom_line( aes( x = ideal, y = y), color = "red" ) +
    theme_classic()
  
  if( !is.na(title) ) p = p + ggtitle(title)
  
  plot(p)
}

# calculate peak speed of cursor
peak_speed = function(x, t){
  
  if ( any(is.na(x)) ) return(NA)
  
  change.in.x = abs( diff(x) )
  change.in.t = diff(t)
  
  # na.rm to handle when change.in.t = 0
  # max( change.in.x / change.in.t, na.rm = TRUE )
  
  x <- tryCatch({
    max( change.in.x / change.in.t, na.rm = TRUE )
  }, warning=function(w) {
    ## do something about the warning, maybe return 'NA'
    stop()
  })
}

