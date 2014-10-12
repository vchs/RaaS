# Massimo Re Ferre'
# www.it20.info
# RaaS CLI is a tool that allows you to interact with your DRaaS subscription
#

require 'httparty'
require 'yaml'
require 'xml-fu'
require 'pp'
require 'awesome_print' #optional - useful for debugging

require 'modules/RaaSCore'


# I stole this piece of code (silence_warnings) from the Internet.
# I am using it to silence the warnings of the certificates settings (below)

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

# this is what the program accepts as input

def usage
  puts "\nUsage: #{$PROGRAM_NAME} operation [option1] [option2]\n"
  puts "\n\toperations: peers|replications|testfailover|testcleanup|failover"
  puts "\n\te.g. #{$PROGRAM_NAME} peers"
  puts "\te.g. #{$PROGRAM_NAME} replications ALL"
  puts "\te.g. #{$PROGRAM_NAME} replications <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} testfailover <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} testfailover ALL"
  puts "\te.g. #{$PROGRAM_NAME} testcleanup <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} testcleanup ALL"
  puts "\te.g. #{$PROGRAM_NAME} failover <VM name>"
  puts "\te.g. #{$PROGRAM_NAME} failover ALL"
  puts "\n"
end


$operation = ARGV[0]
$details = ARGV[1]
$VM = ARGV[2]


if $operation

  raas = RaaS.new
    
  raas.login

  case $operation.chomp

   
  when 'peers'  
  	  peerURI, siteName, siteID = raas.peers
  	  puts "Currently active peer(s):\n".green
  	  peerURI.length.times do |i|
  	  						puts "Site Name   : " + siteName[i]
							puts "Site Id     : " + siteID[i]
							puts "\n"			
						   end
  	  
    
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
    
    
  when 'testfailover'
  	#if the keyword name "ALL is specified we test failover ALL VMs 
    if $details == "ALL"
    	print "Are you REALLY SURE you want to test failover ALL the VMs? (yes/no): ".red
		input = STDIN.gets.chomp
		if input == "yes" 
      		raas.testfailoverALL
      	end
    else
         if $details
         	   # if a name is specified we assume it's a VM and we run testfailoverVM  
         	   foundVM, testfailover = raas.testfailoverVM
         	   #we check if the VM was actually found 
         	   if foundVM == false 
       				puts "Sorry, I couldn not find the VM ".red + $details
      				puts "\n"
     		   else 
     		   		#if the VM was found, we check whether a test failover actually occurred  
    			    if testfailover == false
       					puts "Sorry, the VM ".red + $details + " is not in the proper state to test a failover".red
       					puts "\n"
       				end 
   			   end
         	else usage 
         	end       	
    end
 
 
  when 'testcleanup'
    if $details == "ALL" 
      	raas.testcleanupALL
    else
         if $details 
         	   raas.testcleanupVM
         	else usage 
         	     end       	
    end
       		     
       		     		
  when 'failover'
    if $details == "ALL"
    	print "Are you REALLY SURE you want to failover ALL the VMs for production usage? (yes/no): ".red
		input = STDIN.gets.chomp
		if input == "yes"
         	raas.failoverALL
      	end
    else
         if $details 
         	print "Are you REALLY SURE you want to failover the VM ".red + $details + " for production usage? (yes/no): ".red
			input = STDIN.gets.chomp
			if input == "yes"
         		foundVM, failover = raas.failoverVM
         		if foundVM == false 
  		             puts "Sorry, I couldn't not find the VM ".red + $details
                     puts "\n"
                else 
                   if failover == false
       		         puts "Sorry, the VM ".red + $details + " is not in the proper state to perform a failover".red
       		         puts "\n"
                end 
    end
         	end
         else usage 
         	end
         	
    end    		
       							       		  
else #case
  puts "\n" 
  puts "Wrong operation!".red
  usage
  puts "\n" 

end

  raas.logout

else #if
  puts "\n" 
  puts "Missing operation!".red
  puts "\n" 
  usage

end #main if













































