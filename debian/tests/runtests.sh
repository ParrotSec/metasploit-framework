#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e 

# this function will test if a file exists and checks if it's a valid elf.


#############################################
# this function will run the msfupdate script
#############################################

test_update() {

    msfupdate

}

###########################################
# Test various utilities in tools directory
###########################################

test_tools() {


	echo "Testing if generating an egghunter in py format works correctly..."
	msf-egghunter --egg W00T --format py
	echo "Generating metasploit pattern..."
	msf-pattern_create -l 500
	echo "Locate 3Ak4 in the buffer strings..."
	msf-pattern_offset -l 500 -q 3Ak4
	echo "Testing metasm_shell utility..."
    cat <<EOF > $AUTOPKGTEST_TMP/run_metasm_shell
#!/usr/bin/expect
spawn msf-metasm_shell
expect "metasm >"
send "add esp, 10\n"
expect "metasm >"
send "exit"
EOF

	chmod 755 $AUTOPKGTEST_TMP/run_metasm_shell
	$AUTOPKGTEST_TMP/run_metasm_shell
	echo -e "\nTesting nasm_shell utility..."
	cat <<EOF > $AUTOPKGTEST_TMP/run_nasm_shell
#!/usr/bin/expect
spawn msf-nasm_shell
expect "nasm >"
send "add esp, 10\n"
expect "nasm >"
send "exit"
EOF

	chmod 755 $AUTOPKGTEST_TMP/run_nasm_shell
	$AUTOPKGTEST_TMP/run_nasm_shell
#	disabled because it's temporarily broken:
#       see https://github.com/rapid7/metasploit-framework/issues/9219
#       add a link msf-msu_finder when fixed
#	echo -e "\nTesting msu_finder..."
#	msf-msu_finder -q "ms15-100" -r x86
	msfvenom -p linux/x64/meterpreter/reverse_tcp LPORT=4444 -f exe > $AUTOPKGTEST_TMP/reverse.exe
	echo "Testing exe2vba.rb..."
	msf-exe2vba $AUTOPKGTEST_TMP/reverse.exe $AUTOPKGTEST_TMP/reverse.vba
	echo "Testing exe2vbs.rb..."
	msf-exe2vbs $AUTOPKGTEST_TMP/reverse.exe $AUTOPKGTEST_TMP/reverse.vbs
	echo "Testing find_badchars utility..."
	msfvenom -p windows/exec -f raw -v shellcode CMD=calc.exe EXITFUNC=thread | msf-find_badchars -b "\x00\x0a"

}

###########################################################
# this function runs msfrpcd daemon - depends on screen 
###########################################################

test_msfrpcd() {


	screen -S msfrpcdtest -d -m msfrpcd -U msf -P test -f -S -a 127.0.0.1
	COUNTER=0
	while [[ $(netstat -ltn | grep ":55553 " | wc -l) -eq "0" ]] ; do
		if  [ "$COUNTER" -gt 60 ]; then
			echo "Service msfrpcd still not running after 60 seconds ! exiting..."
			exit 1
		fi
	echo "Service msfrpcd still not listening on port 55553. waiting..."
	sleep 1 
	let COUNTER=COUNTER+1
	done
	echo "Service msfrpcd is now listening on port 55553. testing..."
	msfrpc -U msf -P test -S -a 127.0.0.1 <<-EOF
	rpc.call('core.version')
	rpc.call('core.module_stats')
	exit
	EOF

	screen -X -S msfrpcdtest quit
}

##################################################################
# this function tests masfd deamon - depends on netcat-traditional 
##################################################################

test_msfd() {


	msfd -a 0.0.0.0
	COUNTER=0
	while [[ $(netstat -ltn | grep ":55554 " | wc -l) -eq "0" ]] ; do
	    if  [ "$COUNTER" -gt 60 ]; then
            echo "Service msfd still not running after 60 seconds ! exiting..."
    	    exit 1
	    fi
	    echo "Service msfd still not listening on port 55554. waiting..."
	    sleep 1
	    let COUNTER=COUNTER+1
	done
	echo "Service msfd is now listening on port 55554. testing..."
	echo -e "show exploits\nexit" | nc -v 127.0.0.1 55554 2>/dev/null

}

##############################################################################################
# this function generates a linux bind meterpreter shell
##############################################################################################

test_msfvenom() {


	msfvenom -l all
	echo "Generating calc shellcode in py format"
	msfvenom -p windows/exec -b "\x00\x0a" -f python -v shellcode CMD=calc.exe EXITFUNC=thread 
	msfvenom -p linux/x86/meterpreter/bind_tcp LPORT=4444 -f elf > $AUTOPKGTEST_TMP/bind-shell.elf

}

###############################################################################
# This function pops up a windows meterpreter session - depends on screen, wine
###############################################################################

test_windows_meterpreter() {


	arch=$(dpkg --print-architecture)
	msfvenom -p windows/meterpreter/bind_tcp LPORT=443 -f exe > $AUTOPKGTEST_TMP/shell.exe

	if [ "$arch" == 'amd64' ] || [ "$arch" == 'arm64' ] && [ $(dpkg -s wine32 2>/dev/null | grep -c "ok installed") -eq 0 ]; then

	    echo "Installing wine32 package..."
	    dpkg --add-architecture i386 && apt-get update && apt-get -y install wine32

	fi

	screen -S meterpretertest -d -m wine $AUTOPKGTEST_TMP/shell.exe
    cat <<EOF > $AUTOPKGTEST_TMP/METERPRETER_TEST_FILE
#!/usr/bin/expect
spawn msfconsole
expect "msf >"
send "use multi/handler\n"
expect "msf exploit(handler) >"
send "set PAYLOAD windows/meterpreter/bind_tcp\n"
expect "msf exploit(handler) >"
send "set LPORT 443\n"
expect "msf exploit(handler) >"
send "exploit\n"
expect "meterpreter >"
sleep 1
send "getuid\n"
expect "meterpreter >"
sleep 1
send "ipconfig\n"
expect "meterpreter >"
send "exit\n"
expect "msf exploit(handler) >"
send "exit\n"
EOF

	chmod 755 $AUTOPKGTEST_TMP/METERPRETER_TEST_FILE
	$AUTOPKGTEST_TMP/METERPRETER_TEST_FILE




} 

###########################################################
# This function does th followings: - depends on apache2
#  - Setup the postgre server
#  - Create msf database
#  - Create a workspace
#  - Run few port scans using db_nmap and portscan module 
#  - Test few related commands
###########################################################
    
test_msf_db_port_scan() { 


	# Restart apache2
    service apache2 restart

	echo "Testing Metasploit Database & Scans"
	echo "Start up the postgresql server"
	service postgresql restart
	echo "Create and initialize the msf database"
	/usr/share/metasploit-framework/msfdb init
	echo "Create a list of commands to be executed for this test Case"
	cat <<EOF > $AUTOPKGTEST_TMP/DB_TEST_FILE
db_status
workspace -a scan_test
db_nmap -A 127.0.0.1
hosts
hosts -d
use auxiliary/scanner/portscan/tcp
set RHOSTS 127.0.0.1
run
services
exit
EOF

	msfconsole -r $AUTOPKGTEST_TMP/DB_TEST_FILE


}


#####################################################################
# This function runs few tests on msfconsole - depends on apache2
#####################################################################


test_msfconsole() {

	# Restart apache2
    service apache2 restart
	echo "Start up the postgresql server"
	service postgresql restart
	echo "Create and initialize the msf database"
	/usr/share/metasploit-framework/msfdb init
	cat <<EOF > $AUTOPKGTEST_TMP/CONSOLE_TEST_FILE
help
db_status
ping -c 1 127.0.0.1
show exploits
connect -z 127.0.0.1 80
load pcap_log
unload pcap_log
db_status
db_rebuild_cache
search name:apache platform:linux
load wmap
wmap_sites -a http://127.0.0.1
wmap_sites -l
wmap_targets -t http://127.0.0.1
wmap_targets -l
wmap_run -t
wmap_run -e
wmap_vulns -l
exit
EOF

	echo "running nsfconsole...."
	msfconsole -h
	msfconsole -r $AUTOPKGTEST_TMP/CONSOLE_TEST_FILE

}


###################################
# Main 
###################################

for function in "$@"; do
	$function
done
