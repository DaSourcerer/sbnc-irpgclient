catch {
	package require Tcl 8.4; # Tcl minimum version
	package require bnc; # shroudBNC Tcl package
}

internalbind server irpg:server JOIN
internalbind command irpg:command

proc irpg:server {client arguments} {
	global irpgbot irpguser irpgpass irpghostmask

	if { [string equal [getbncuser $client tag irpgchan] ""] } {
		return
	} elseif { ![string equal -nocase [lindex $arguments 1] "JOIN"] } {
		return
	} elseif { [getbncuser $client tag irpguser]!= "" } {
		set irpguser [getbncuser $client tag irpguser]
	} else {
		set irpguser $::botnick
	}
	set irpgpass [getbncuser $client tag irpgpass]
	set irpghostmask [getbncuser $client tag irpghostmask]
	
  set uhost [lindex $arguments 0]
  set channel [string tolower [lindex $arguments 2]]

  if { [string equal -nocase [getbncuser $client tag irpgchan] $channel] } {
 		set nick [string tolower [lindex [split $uhost "!"] 0]]
  	if { [string match -nocase $irpghostmask $uhost] } {
  		set irpgbot $nick
  		# Wait 5 seconds before actually authing in order to allow
			# authentication scripts for Q/ChanServ/Whatever to finish.
			# 5 seconds are plenty of time in networks!
			utimer 5 [list irpg:auth $irpgbot]
  	} elseif { [string equal -nocase $nick $::botnick] } {
  		set irpgbot [lindex [split $irpghostmask "!"] 0]
 	  	bind raw - 311 irpg:whoisBot
 	  	bind raw - 401 irpg:whoisFail
 	  	putserv "WHOIS $irpgbot"
    }
  }
}

proc irpg:auth { bot } {
	global irpguser irpgpass
	bind notc - "Logon successful. Next level in*" irpg:authSuccess
	bind notc - "Sorry,*" irpg:authFail
	putserv "PRIVMSG $bot :LOGIN $irpguser $irpgpass" 
}

proc irpg:whoisBot { from keyword arg } {
	global irpghostmask
	unbind raw - 311 irpg:whoisBot
	unbind raw - 401 irpg:whoisFail
	
	set botnick [lindex [split $arg " "] 1]
	set botuser [lindex [split $arg " "] 2]
	set bothost [lindex [split $arg " "] 3]
	
	if { [string match -nocase $irpghostmask "$botnick!$botuser@$bothost"] } {
		utimer 5 [list irpg:auth $botnick]
	} else {
		putlog "Could resolve $botnick!$botuser@$bothost but hostmask did not match. Giving up for security reasons, sorry!"
	}
}

proc irpg:whoisFail { from keyword arg } {
	global irpgbot
	unbind raw - 311 irpg:whoisBot
	unbind raw - 401 irpg:whoisFail
	putlog "Failed to resolve $irpgbot. Giving up, sorry!"
}

proc irpg:authSuccess {nick uhost hand text dest} {
	global irpgbot
	if { [string match -nocase $irpgbot $nick] } {
		putlog "Successfully logged in"
		unbind notc - "Logon successful. Next level in*" irpg:authSuccess
		unbind notc - "Sorry,*" irpg:authFail	
	}
}

proc irpg:authFail {nick uhost hand text dest} {
	global irpgbot
	if { [string match -nocase $irpgbot $nick] } {
		putlog "Automatic login failed. Original message: $text"
		unbind notc - "Logon successful. Next level in*" irpg:authSuccess
		unbind notc - "Sorry,*" irpg:authFail			
	}
}

proc irpg:replyset {params} {
	setctx [lindex $params 0]

	bncreply "irpguser - [lindex $params 1]"
	bncreply "irpgpass - [lindex $params 2]"
	bncreply "irpgchannel - [lindex $params 3]"
	bncreply "irpghostmask - [lindex $params 4]"
}

proc irpg:command {client parameters} {
	if {[string equal -nocase [lindex $params 0] "set"]} {
		if {[llength $params] < 3} {
			if {[getbncuser $client tag irpguser] != ""} {
				set irpguser [getbncuser $client tag irpguser]
			} else {
				set irpguser "Not set"
			}
	
			if {[getbncuser $client tag irpgpass] != ""} {
				set irpgpass "Set"
			} else {
				set irpgpass "Not set"
			}

			if {[getbncuser client tag irpgchannel != ""} {
				set irpgchannel "Set"
			} else {
				set irpgchannel "Not set"
			}

			if {[getbncuser client tag irpghostmask != ""} {
				set irpghostmask "Set"
			} else {
				set irpghostmask "Not set"
			}

			internaltimer 0 0 irpg:replyset [list [getctx 1] $irpguser $irpgpass $irpgchannel $irpghostmask]

			return
		}

		if {[string equal -nocase [lindex $params 1] "irpguser"]} {
			setbncuser $client tag irpguser [lindex $params 2]
			bncreply "Done."
			haltoutput
		}

		if {[string equal -nocase [lindex $params 1] "irpgpass"]} {
			setbncuser $client tag irpgpass [lindex $params 2]
			bncreply "Done."
			haltoutput
		}

		if {[string equal -nocase [lindex $params 1] "irpgchannel"]} {
			setbncuser $client tag irpgchannel [lindex $params 2]
			bncreply "Done."
			haltoutput
		}

		if {[string equal -nocase [lindex $params 1] "irpghostmask"]} {
			setbncuser $client tag irpghostmask [lindex $params 2]
			bncreply "Done."
			haltourput
		}
	}
}

proc irpg:ifacecmd {command params account} {
	switch -- $command {
		"getirpguser" {
			return [getbncuser $account tag irpguser]
		}
		"setirpguser" {
			setbncuser $account tag irpguser [lindex $params 0]
			return 0
		}
		"getirpgpass" {
			return [getbncuser $account tag irpgpass]
		}
		"setirpgpass" {
			setbncuser $account tag irpgpass [lindex $params 0]
			return 0
		}
		"getirpghostmask" {
			return [getbncuser $account tag irpghostmask]
		}
		"setirpghostmask" {
			setbncuser $account tag irpghostmask [lindex $params 0]
			return 0
		}
		"getirpgchannel" {
			return [getbncuser $account tag irpgchan]
		}
		"setirpgchannel" {
			setbncuser $account tag irpgchan [lindex $params 0]
			return 0
		}
	}
}

if {[lsearch -exact [info commands] "registerifacehandler"] != -1} {
	registerifacehandler irpg irpg:ifacecmd
}
