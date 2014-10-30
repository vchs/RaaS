#################################################################################
####                           Massimo Re Ferre'                             ####
####                             www.it20.info                               ####
####  RaaSCLI, a tool that allows you to interact with a DRaaS subscription  ####
#################################################################################


  
#################################################################################
####  RaaSmain.rb is the front end program that presents the CLI interface   ####
####              It leverages the RaaSCore library                          ####
####    Per best practices I keep the logic separate from the presentation   ####
#################################################################################


#################################################################################
####                              IMPORTANT !!                               ####
####  The program reads a file called RaaSCLI.yml in the working directory   ####
####        If the file does not exist the program will abort                ####
####  The file is used to provide the program with connectivity parameters   ####
#################################################################################

# This is the format of the RaaSCLI.yml file:
# :username: email@domain@OrgName
# :password: password
# :site: https://vcd-url


# These are the additional modules/gems required to run the program 

require 'httparty'
require 'yaml'
require 'xml-fu'
require 'pp'
require 'awesome_print' #optional - useful for debugging

require 'modules/RaaSCore'


# We stole this piece of code (silence_warnings) from the Internet.
# We am using it to silence the warnings of the certificates settings (below)

def silence_warnings(&block)
  warn_level = $VERBOSE
  $VERBOSE = nil
  result = block.call
  $VERBOSE = warn_level
  result
end


# This bypass certification checks...  NOT a great idea for production but ok
# for test / dev This will be handy for when this script will work with vanilla
# vCD setups (not just vCHS)

silence_warnings do
	OpenSSL::SSL::VERIFY_NONE = OpenSSL::SSL::VERIFY_NONE
end 

# This is what the program accepts as input

def usage
  puts "\nUsage: #{$PROGRAM_NAME} operation [option1] [option2]\n"
  puts "\n\toperations: peers|replications|testfailover[or test]|testcleanup[or cleanuptest]|failover[or recovery]"
  puts "\n\te.g. #{$PROGRAM_NAME} peers"
  puts "\te.g. #{$PROGRAM_NAME} replications ALL"
  puts "\te.g. #{$PROGRAM_NAME} replications <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} testfailover [or test] <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} testfailover [or test] ALL"
  puts "\te.g. #{$PROGRAM_NAME} testcleanup [or cleanuptest] <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} testcleanup [or cleanuptest] cleanuptest ALL"
  puts "\te.g. #{$PROGRAM_NAME} failover [or recovery] <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} failover [or recovery] recovery ALL"
  puts "\n"
  
end


# These are the variables the program accept as inputs (see the usage section for more info)

if ARGV[0] 
	$operation = ARGV[0].downcase
end

$details = ARGV[1]

# The if checks if the user called an operation. If not the case, we print the text on how to use the CLI  

if $operation

# Here we instantiate the RaaS class in RaaSCore

  raas = RaaS.new
  
  
# We login (the login method is in RaaSCore)  

  puts "Logging in ...\n\n"
  raas.login
  

# Here we check what operations a user wants the CLI to execute. Every operations calls a particular method 
# and prints the result returned from the method
# In general, the way RaaSmain works is that it calls specific methods available in RaaSCore.
# Some of these methods requires argument(s). Some do not. 
# Usually these methods returns one or more arrays with information related to the operation being called. 
# For more detailed info on these methods please refer to RaaSCore.  

  case $operation.chomp


# The peers operation calls the peers method and prints the results
# The method doesn't require an argument and it returns three arrays that includes information re the peers
 
   
  when 'peers'  
  	  peerURI, siteName, siteID = raas.peers
  	  puts "Currently active peer(s):\n".green
  	  peerURI.length.times do |i|
  	  						puts "Site Name   : " + siteName[i]
							puts "Site Id     : " + siteID[i]
							puts "\n"			
						   end
  	  
  
  # The replications operation calls the replications method and prints the results.
  # The replications method requires an argument (the details entered by the user) and returns
  # a number of arrays whose rows describe the characteristics and status of each active replication 
    
  when 'replications'
    if $details 
      foundVM, vmname, rpo, replicationState, quiesceGuestEnabled, paused, currentRpoViolation, testRecoveryState, recoveryState, vmhref = raas.replications($details)
      puts 'Detailed information for currently active replication(s):'.green
      puts "\n"
      if foundVM == false 
      	 puts "Sorry, I could not find the VM(s)".red
      	 puts "\n"
      else 
      vmname.length.times do |i|
  	  					puts 'VM name               : ' + vmname[i].blue
         				puts 'RPO                   : ' + rpo[i]
     					puts 'Replication State     : ' + replicationState[i]
   	     				puts 'Quiesce Enabled       : ' + quiesceGuestEnabled[i]
        				puts 'Paused                : ' + paused[i]
         				puts 'Current RPO Violation : ' + currentRpoViolation[i]
         				puts 'Test Recovery State   : ' + testRecoveryState[i]
         				puts 'Recovery State        : ' + recoveryState[i]
         				puts 'VM URL                : ' + vmhref[i]
						puts "\n"			
						end
      end 
    else
      usage
    end  
    


  # The testfailover operation calls one of the testfailover methods and prints the results.
  # We check wether the user either wants to testfailover ALL VMs (in which case we call the testfailoverALL method) 
  # and print results or wants to testfailover one specific VM (in which case we call the testfailoverVM method)
  # and print results
    
  when 'testfailover', 'test'
  	#if the keyword name "ALL is specified we test failover ALL VMs 
    if $details == "ALL"
    	print "Are you REALLY SURE you want to test failover ALL the VMs? (yes/no): ".red
    	puts "\n"
    	puts "\n"
		input = STDIN.gets.chomp
		if input == "yes"
			puts 'Performing a test failover of all VMs. This may be a long task. Please wait.'.green
    		puts "\n" 
      		vmname, testfailover = raas.testfailoverALL
      	    # Here we iterarte through the two arrays returned and print the VMs name and whether the testfailover was executed or not
      	    vmname.length.times do |i| 	  	    
        	if testfailover[i] == false
        	      puts "Sorry, the VM ".red + vmname[i] + " is not in the proper state to test a failover".red
       		      puts "\n"
       		else
       		      puts "Performing a test failover of VM ".green + vmname[i] + ". Please wait.".green
       		      puts "\n"
       	    end # if #testfailover == false
            end #do 
        end #if input == "yes"
    else
         if $details
         	   # if the details parameter is specified we assume it's a VM name and we run testfailoverVM
         	   puts 'Performing a test failover of VM '.green + $details + '. Please wait.'.green
    		   puts "\n" 
         	   foundVM, testfailover = raas.testfailoverVM($details)
      		   # Here we check whether the VM name in input actually maps a VM name in the service
         	   if foundVM == false 
       				puts "Sorry, I couldn not find the VM ".red + $details
      				puts "\n"
     		   else 
     		   		# If the VM name matches, here we check if the testfailover has actually occurred     
    			    if testfailover == false
       					puts "Sorry, the VM ".red + $details + " is not in the proper state to test a failover".red
       					puts "\n"
       				end 
   			   end
         	else usage 
         	end       	
    end
 

  # The testcleanup operation calls one of the testcleanup methods and prints the results.
  # We check wether the user either wants to testcleanup ALL VMs (in which case we call the testcleanupALL method) 
  # and print results or wants to testcleanup one specific VM (in which case we call the testcleanupVM method)
  # and print results
  
  when 'testcleanup', 'cleanuptest'
     #if the keyword name "ALL is specified we test cleanup ALL VMs 
    if $details == "ALL"
        print "Are you REALLY SURE you want to clean up ALL the VMs? (yes/no): ".red
        puts "\n"
    	puts "\n"
		input = STDIN.gets.chomp
		if input == "yes"
			puts 'Performing a test cleanup of all VMs. This may be a long task. Please wait.'.green
    		puts "\n" 
    		vmname, testcleanup = raas.testcleanupALL
    	    # Here we iterarte through the two arrays returned and print the VMs name and whether the testcleanup was executed or not
      	    vmname.length.times do |i| 	  	    
        	if testcleanup[i] == false
        	      puts "Sorry, the VM ".red + vmname[i] + " is not in a test failover state that allows a clean up".red
       		      puts "\n"
       		else
       		      puts "Performing a testcleanup of VM ".green + vmname[i] + ". Please wait.".green
       		      puts "\n"
       	    end #if testcleanup == false
    	    end #do
         end #if input == "yes"
    else
         if $details
               # if the details parameter is specified we assume it's a VM name and we run testcleanupVM
               puts "Performing a testcleanup of VM ".green + $details + '. Please wait.'.green
               puts "\n"
         	   foundVM, testcleanup = raas.testcleanupVM($details)
         	   # Here we check whether the VM name in input actually maps a VM name in the service
         	   if foundVM == false 
   					puts "Sorry, I couldn't not find the VM ".red + $details
   					puts "\n"
   			   else
   			   # If the VM name matches, here we check if the testcleanup has actually occurred     
   					if testcleanup == false 
   						puts "Sorry, the VM ".red + $details + " is not in a test failover state that allows a clean up".red
   						puts "\n"
			        end
   		       end
            else usage 
            end       	
    end       		     


  # The failover operation calls one of the failover methods and prints the results.
  # We check wether the user either wants to failover ALL VMs (in which case we call the failoverALL method) 
  # and print results or wants to failover one specific VM (in which case we call the failoverVM method)
  # and print results

  when 'failover', 'recovery'
    #if the keyword name "ALL is specified we failover ALL VMs 
    if $details == "ALL"
    	print "Are you REALLY SURE you want to failover ALL the VMs for production usage? (yes/no): ".red
		input = STDIN.gets.chomp
		if input == "yes"
			puts 'Performing a failover of all VMs. This may be a long task. Please wait.'.green
    		puts "\n"
         	vmname, failover = raas.failoverALL
         	# Here we iterarte through the two arrays returned and print the VMs name and whether the failover was executed or not
      	    vmname.length.times do |i| 	 
        	if failover[i] == false
        	      puts "Sorry, the VM ".red + vmname[i] + " is not in the proper state to failover".red
       		      puts "\n"
       		else
       		      puts "Performing a failover of VM ".green + vmname[i] + ". Please wait.".green
       		      puts "\n"
       	    end # if failover == false
            end #do 
        end #if input == "yes"
    else
         if $details 
            # if the details parameter is specified we assume it's a VM name and we run failoverVM
            print "Are you REALLY SURE you want to failover the VM ".red + $details + " for production usage? (yes/no): ".red
			input = STDIN.gets.chomp
			if input == "yes"
         		puts 'Performing the failover of VM '.green + $details + ' for production usage. Please wait.'.green
    		    puts "\n"
    		    # Here we check whether the VM name in input actually maps a VM name in the service
         		foundVM, failover = raas.failoverVM($details)
         		if foundVM == false 
  		             puts "Sorry, I couldn't not find the VM ".red + $details
                     puts "\n"
                else 
                   # If the VM name matches, here we check if the failover has actually occurred     
                   if failover == false
       		         puts "Sorry, the VM ".red + $details + " is not in the proper state to perform a failover".red
       		         puts "\n"
                end 
    end
         	end
             else usage 
             end
    end #if    		
       			
# If the user specified a wrong operation we suggest how to use the CLI 
       							       		  
else #case
  puts "\n" 
  puts "Wrong operation!".red
  usage
  puts "\n" 

end

# At this stage RaaSmain will have executed an operation per the "case" above" and it logs out

  puts "Logging out ...\n\n"
  raas.logout


# If the user did not specify an operation at all we suggest how to properly use the CLI 

else #if
  puts "\n" 
  puts "Missing operation!".red
  puts "\n" 
  usage

end #main if













































