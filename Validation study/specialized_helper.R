

# Contact: Maya Mathur (mmathur@stanford.edu)

############################### ROUND WITH TRAILING ZEROES ###############################

my_round = function(x, digits) {
  format( round( x, digits ), nsmall = digits )
}


############################### STANDARDIZE A VARIABLE ###############################

# standardize a continuous variable
standardize = function(x) {
  ( x - mean(x) ) / sd(x)
}

############################### VIOLIN PLOTS ###############################

my_violins = function( Yname ) {

  library(geepack)
  
  # remove any infinite values
  bad = ( l[[Yname]] == Inf )
  
  l2 = l[ bad == FALSE, ]
  
  if ( any(bad == TRUE, na.rm = TRUE) ){
    warning( "Removed ", sum(bad == TRUE, na.rm = TRUE ),
             " infinite values from ", Yname, sep="")
  }
  
  # regression to get p-value and coefficient
  type = "ols"
  if ( Yname == "xflips" ) type = "poisson"
  
  if (type == "ols"){
    
    m = geeglm( l2[[Yname]] ~ confusing * weird.scaling * wts,
                data = l2,
                id = ResponseId,
                #scale.fix = TRUE,
                corstr = "exchangeable" )

    bhat = coef(m)["confusing1"]
    pval = coef(summary(m))["confusing1", "Pr(>|W|)"]
    
  } else if (type == "poisson") {
    
    m = geeglm( l2[[Yname]] ~ confusing * weird.scaling * wts,
                data = l2,
                id = ResponseId,
                family = poisson,
                #scale.fix = TRUE,
                corstr = "exchangeable" )

    bhat = exp( coef(m)["confusing1"] )
    pval = coef(summary(m))["confusing1", "Pr(>|W|)"]

  }
  
  # make prettier variable for X-axis
  l2$confus.cat = NA
  l2$confus.cat[ l2$confusing == 1 ] = "Ambiguous"
  l2$confus.cat[ l2$confusing == 0 ] = "Unambiguous"
  
  # give better Y-axis titles
  if ( Yname == "xflips" ) ylab = "x-flips (count)"  
  if ( Yname == "area" ) ylab = "Area (std.)" 
  if ( Yname == "xdev" ) ylab = "Max x-deviation (std.)" 
  if ( Yname == "speed" ) ylab = "Peak speed (std.)" 
  if ( Yname == "rxnt" ) ylab = "Reaction time (std.)" 

  # nicely format the p-value and beta-hat
  library(MetaUtility)
  if ( pval < 0.0001 ) pstring = "(p < 0.0001)" else pstring = paste( "(p = ", round( pval, 4 ), ")", sep = "" )
  bstring = format_stat( bhat, digits = 2, cutoffs = c(0.001, 1e-5) )

  if ( type == "poisson" ) title = bquote( e^hat(beta) ~ " = " ~ .(bstring) ~ .(pstring) )
  if( type == "ols" ) title = bquote( hat(beta) ~ " = " ~ .(bstring) ~ .(pstring) )
  

  p = ggplot( data = l2, aes( x = confus.cat, y = l2[[Yname]] ) ) +
    geom_violin(draw_quantiles=c(.5)) +
    #stat_summary(fun.y = "mean", geom = "point", shape = 8, size = 3, color = "red") +
    scale_y_continuous( limits = c(  quantile( l[[Yname]], 0.03, na.rm=TRUE ),
                                   quantile( l[[Yname]], 0.97, na.rm=TRUE ) ) ) +
    theme_classic() +
    ylab(ylab) + 
    xlab("Stimulus type") + 
    ggtitle(title) +
    theme(plot.title = element_text(hjust = 0.5)) # center title
  
  return(p)
}
