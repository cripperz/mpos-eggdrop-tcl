#
# MPOS eggdrop users
#


######################################################################
##########           nothing to edit below this line        ##########
##########           use config.tcl for setting options     ##########
######################################################################


# key bindings
#
bind pub - !adduser user_add
bind pub - !deluser user_del
bind pub - !request user_request

proc check_mpos_user {username hostmask} {
	global debug scriptpath registereduserfile

  	# setting logfile to right path
	set userfilepath $scriptpath
  	append userfilepath $registereduserfile
	
  	if { [file_read $userfilepath] eq "0" } {
  		putlog "failed reading userfile"
  		return "false"
  	} else {

		set text [FileTextRead $userfilepath]
		foreach line [split $text \n] {
			#putlog "$line - $hostmask"
  	  		if {[string match "[string tolower $hostmask]" $line] } {
  				#if {$debug eq "1"} { putlog "user exists"}
  				set userhasrights "true"
				break
  	  		} else {
  				#if {$debug eq "1"} { putlog "user not found"}
  				set userhasrights "false"
			}
		}
  	}
  	return $userhasrights
  	
}

proc user_add {nick uhost hand chan arg} {
	global debug scriptpath registereduserfile

	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick tried to add $arg to userfile"
		return
	}
 
  	# setting logfile to right path
	set userfilepath $scriptpath
  	append userfilepath $registereduserfile
  	
  	if {$arg eq ""} {
  		putlog "no user to add"
  		return
  	} 

	set arg [charfilter $arg]
	set hostmask "$arg!*[getchanhost $arg $chan]"
	set usertoadd "false"
		
	if { [file_read $userfilepath] eq "0" } {
			
		# check if userfile exists
		#
		if { [file_check $userfilepath] eq "0" } {
			if {$debug eq "1"} { putlog "file $userfilepath does not exist" }
			
			if {[file_write $userfilepath [string tolower $hostmask]] eq "1" } { 
				if {$debug eq "1"} { putlog "file $userfilepath created" }
			}
			
		} else {
			if {$debug eq "1"} { putlog "can't read $userfilepath"}
		}

	} else {
	
		set mposuserfile [open $userfilepath]
		# Read until we find the start pattern
		while {[gets $mposuserfile line] >= 0} {
			putlog "$line - $hostmask"
  	  		if { [string match "[string tolower $hostmask]" $line] } {
				if {$debug eq "1"} { putlog "user exists"}
				set usertoadd "false"
				break
  	  		} else {
  	  			set usertoadd "true"
			}
		}
		close $mposuserfile
			
	}
	
	if {$usertoadd eq "true"} {
		if {[file_write $userfilepath [string tolower $hostmask]] eq "1" } { 
			if {$debug eq "1"} { putlog "user added"}
		}
	}

	if {$debug eq "1"} { putlog "Hostmask is: [string tolower $hostmask]"}
	
}

proc user_del {nick uhost hand chan arg} {
	global debug scriptpath registereduserfile

	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick tried to add $arg to userfile"
		return
	}

  	if {$arg eq ""} {
  		putlog "no user to add"
  		return
  	}
  	
  	# setting logfile to right path
	set userfilepath $scriptpath
  	append userfilepath $registereduserfile
  	
	set arg [charfilter $arg]
	set hostmask "$arg!*[getchanhost $arg $chan]"

	set text [FileTextRead $userfilepath]
	set linenumber 0
	foreach line [split $text \n] {
		#putlog "$line"
		if { [string match "[string tolower $hostmask]" $line] } {
			putlog "user found in line $linenumber"
			if {[FileDeleteLine $userfilepath $linenumber $linenumber] eq "1"} {
				putlog "success"
			} else {
				putlog "error"
			}
			break
		}
		incr linenumber
	}

}

proc user_request {nick uhost hand chan arg} {
	putquick "NOTICE $nick :your request will be processed shortly, please be patient"
}


putlog "===>> Mining-Pool-Users - Version $scriptversion loaded"

