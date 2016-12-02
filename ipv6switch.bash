#!/bin/bash

:   '

This script creates a list of network interfaces, allowing the user to selectively
enable/disable IPv6 on the available network interfaces
 

------------------------------------------------------------------------|
                                                                        |
Below here there be input menus, which the user interacts with:         |
                                                                        |
------------------------------------------------------------------------|'

# Where everything comes together:
MAINMENU () 
{  

    networkArray=(/sys/class/net/*)

    infCount=${#networkArray[@]}
     
    # Draw the list and junk menu:
    
    NETIFLIST
    OPTIONSLIST
    echo
    
    while read -p "    Enter interface # or command option ([c] to reset): " userSel ;
    do
        # This test case checks if the number is an integer.
        # If it is, the menu will go on to change the IPv6 status for
        # the selected interface (or not).
        if [[ $userSel =~ ^-?[0-9]+$ ]] ; 
        then
            MENU_ISINT

        else 
            MENU_NOTINT
        fi
    done
}

# Function for when $userSel is an integer:
MENU_ISINT ()
{
    # This if and elif filter out bad numbers:
    if [ $userSel -gt $infCount ] ;
    then
        echo
        printf '%s\t%s\n' "" "-- ERROR : It seems that you entered a number greater than the range of available network interfaces. --"
        echo

    elif [ $userSel -lt $((0)) ] ; 
    then
        echo
        printf '%s\t%s\n' "" "-- ERROR : It seems that you entered a number less than the range of available network interfaces... somehow. --"

    # Only correct entries should get to this point:
    else
        echo
        printf '%s\t%s\n' "" "Confirm that this is the interface you wish to switch IPV6 for: [${networkArray[$userSel]##*/}]"
        echo
        printf '%s\t%s\n' "" "Options: [y]es / [n]o / [i]fconfig details" 
        while read -p "        Is this correct? [y/n/i]: " -n 1 finalConfirm ;
        do
            # If confirmed, this will bring the user to the
            # MENU_IP6SWITCH function, to change the IPv6 status:
            if [[ "$finalConfirm" == [yY] ]] ;
            then
                echo && echo
                IP6SWITCH
                break
            
            # This will newline and go back a step 
            elif [[ "$finalConfirm" == [nN] ]] ;
            then
                echo
                break #brings the user back to MAINMENU func
            
            # Allows a chance for the user to double-check the interface's details:
            elif [[ "$finalConfirm" == [iI] ]] ;
            then
                echo && echo
                rulem "[INTERFACE DETAILS: ${networkArray[$userSel]##*/}]"
                sudo ifconfig ${networkArray[$userSel]##*/}

            fi
        done
        echo
    fi
}

# Function for when $userSel is not an integer. This will test the user input against the valid
# verbal commands available, or tell the user to check up on their typing skills:
MENU_NOTINT ()
{
    if [[ "$userSel" == [cC] ]] ;
    then
        clear
        MAINMENU

    elif [[ "$userSel" == [iI] ]] ;
    then
        sudo ifconfig -a | less
        echo

    elif [[ "$userSel" == [nN] ]] ;
    then
        echo
        netstat -i
        echo

    # this accounts for any text that is not a valid command: 
    else
        echo
        printf '%s\t%s\n' "" "-- ERROR : It seems that what you input was empty or was not an available option. --"
        echo
    fi
}


# This is where the disabling/enabling) of IPv6 happens:
IP6SWITCH ()
{
    # Read the status of the selected device, and do some menu logic:
    currentStatus=$(cat /proc/sys/net/ipv6/conf/${networkArray[$userSel]##*/}/disable_ipv6)
    if [[ $currentStatus == $((1)) ]] ;
    then
        switchMode="enable"
        pastTense="enabled"
        switchTo=$((0))
    else
        switchMode="disable"
        pastTense="disabled"
        switchTo=$((1))
    fi

    printf '%s\t%s\n' "" "Attempting to $switchMode IPv6 on [${networkArray[$userSel]##*/}] ..."
    printf '%s\t%s\n' "" "You may be asked for sudo credentials for this command:"
    printf '%s\t%s\n' "" "\$echo $switchTo | sudo tee /proc/sys/net/ipv6/conf/${networkArray[$userSel]##*/}/disable_ipv6"
    sleep 0.2
    # Piping the output to /dev/null prevents the command from printing $switchTo in the shell:
    echo $switchTo | sudo tee /proc/sys/net/ipv6/conf/${networkArray[$userSel]##*/}/disable_ipv6 > /dev/null
    echo
    printf '%s\t%s\n' "" "IPv6 has been $pastTense on [${networkArray[$userSel]##*/}]." 
    echo
    read -p "   Press the return key to reset the menu..."
    clear
    MAINMENU
}


:   '
------------------------------------------------------------------------|
                                                                        |
All of these functions below do the pretty/dirty work, like drawing     |
separation lines or printing lists.                                     |
                                                                        |
------------------------------------------------------------------------|'

# Read about the rule/rulem functions here:
# http://brettterpstra.com/2015/02/20/shell-trick-printf-rules/
# Draws line with supplied character (defaults with '-'):
rule ()
{
    printf -v _hr "%*s" $(tput cols) && echo ${_hr// /${1--}}
}
rulem ()  
{
	if [ $# -eq 0 ]; then
		echo "Usage: rulem MESSAGE [RULE_CHARACTER]"
		return 1
	fi
	printf -v _hr "%*s" $(tput cols) && echo -en ${_hr// /${2--}} && echo -e "\r\033[2C$1"
}

# This one prints centered text. Found in:
# https://codereview.stackexchange.com/questions/94449/text-centering-function-in-bash
centerText()
{
    textsize=${#1}
    width=$(tput cols)
    span=$((($width + $textsize) / 2))
    printf "%${span}s\n" "$1"
}

# Lists network interfaces to choose, beginning with 0.
NETIFLIST ()
{
    counter=$((0))
    rulem "[CURRENT NETWORK INTERFACES]" "┉" ;
    for netinf in "${networkArray[@]}" ;
    do
        # read the current IPv6 status of the current device in the iteration:
        ipv6Status=$(cat /proc/sys/net/ipv6/conf/${networkArray[$counter]##*/}/disable_ipv6)
        if [[ $ipv6Status == "1" ]];
        then
            report="OFF"
        elif [[ $ipv6Status == "0" ]];
        then
            report="ON"
        else
            report="UNKNOWN"
        fi
        
        # put it all together:
        printf '%s\t%s\t%s\n' "  »  $counter. $netinf" "-- IPv6: $report" ""
        counter=$((counter+1))
    done
}

# Junk menu:
OPTIONSLIST ()
{
    printf '%s\n' "  ╔══════════════╗"
    rulem "╣ MENU OPTIONS ╠" "═"
    printf '%s\n' "  ╠══════════════╝"
    printf '%s\n' "  ╠═» Select an interface to switch IPv6 on/off by entering its listed number."
    printf '%s\n' "  ╠═» [c] - clears screen, resets list and menu."
    printf '%s\n' "  ╠═» [i] - reads ifconfig output (runs: \$sudo ifconfig -a | less)."
    printf '%s\n' "  ╚═» [n] - prints shorter list of interface details (runs: \$netstat -i)."
    echo 
    rulem "[INPUT YOUR DECISION]" "─" && sleep 0.25
}

# Make it all happen: 

clear
centerText "[IPv6 SWITCH SCRIPT]"
MAINMENU
