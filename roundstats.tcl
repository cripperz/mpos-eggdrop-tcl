#
# MPOS eggdrop Calls
# 
# Round Statistics
#

######################################################################
##########           nothing to edit below this line        ##########
##########           use config.tcl for setting options     ##########
######################################################################

# round info
#
proc round_info {nick host hand chan arg } {
 	global help_blocktime help_blocked channels debug debugoutput output
	package require http
	package require json
	package require tls

	if {$arg eq ""} {
		if {$debug eq "1"} { putlog "no pool submitted" }
		return
	}
	
 	set action "index.php?page=api&action=getdashboarddata&api_key="
 	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}

  	set pool_info [regexp -all -inline {\S+} [pool_vars $arg]]
  	
  	if {$pool_info ne "0"} {
  		if {$debug eq "1"} { putlog "COIN: [lindex $pool_info 0]" }
  		if {$debug eq "1"} { putlog "URL: [lindex $pool_info 1]" }
  		if {$debug eq "1"} { putlog "KEY: [lindex $pool_info 2]" }
  	} else {
  		if {$debug eq "1"} { putlog "no pool data" }
  		return
  	} 
  	
  	set newurl [lindex $pool_info 1]
  	append newurl $action
  	append newurl [lindex $pool_info 2]

    if {[string match "*https*" [string tolower $newurl]]} {
  		set usehttps 1
    } else {
    	set usehttps 0
    }
    
  	if {$usehttps eq "1"} {
  		::http::register https 443 tls::socket
  	}
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
    if {$usehttps eq "1"} {
    	::http::unregister https
    }
    
    if {$debugoutput eq "1"} { putlog "xml: $data" }
    
    if {$data eq "Access denied"} { 
    	putquick "PRIVMSG $chan :Access to Roundinfo denied"
    	return 0 
    }
    
    set results [::json::json2dict $data]
	
	foreach {key value} $results {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $value {
			#putlog "Sub: $sub_key - $sub_value"
			foreach {elem elem_val} $sub_value {
				#putlog "Ele: $elem - Val: $elem_val"
				
				
				if {$elem eq "pool"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						if {$elem2 eq "shares"} {
							foreach {elem3 elem_val3} $elem_val2 {
								#putlog "Ele: $elem3 - Val: $elem_val3"
								
								if {$elem3 eq "valid"} { set shares_valid "$elem_val3" }
								if {$elem3 eq "invalid"} { set shares_invalid "$elem_val3" }
								if {$elem3 eq "estimated"} { set shares_estimated "Estimated Shares: $elem_val3" }
								if {$elem3 eq "progress"} { set shares_progress "Progress: $elem_val3 %" }
								
							}
						}
					}				
				}
				
				if {$elem eq "network"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {

						if {$elem2 eq "block"} { set net_block "Block: #$elem_val2" }
						if {$elem2 eq "difficulty"} { set net_diff "Difficulty: $elem_val2" }

					}				
				}				
				
			}
		}
	}
	
	set allshares [expr $shares_valid+$shares_invalid]

	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :Actual Round on [string toupper [lindex $arg 0]] Pool"
 		putquick "PRIVMSG $chan :$net_block | $net_diff | $shares_estimated | Sharecount: $allshares | Shares valid: $shares_valid | Shares invalid: $shares_invalid | $shares_progress"	
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :Actual Round on [string toupper [lindex $arg 0]] Pool"
 		putquick "NOTICE $nick :$net_block | $net_diff | $shares_estimated | Sharecount: $allshares | Shares valid: $shares_valid | Shares invalid: $shares_invalid | $shares_progress"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

putlog "===>> Mining-Pool-Roundstats - Version $scriptversion loaded"