
class RaaS
  include HTTParty
  format :xml
  
  
#################################################################################
####        The following functions are standard functions to login          ####
####                     and logout from the tenant                          ####
#################################################################################
  
  
  
  def initialize(file_path = 'RaaSCLI.yml')
    fail "no file #{file_path}" unless File.exists? file_path
    configuration = YAML.load_file(file_path)
    self.class.basic_auth configuration[:username], configuration[:password]
    self.class.base_uri configuration[:site]
    self.class.default_options[:headers] = { 'Accept' => 'application/*+xml;version=5.6' }
  end

  def login
    puts "Logging in ...\n\n"
    response = self.class.post('/api/sessions')
    # setting global cookie var to be used later on
    @cookie = response.headers['set-cookie']
    self.class.default_options[:headers] = { 'Accept' => 'application/*+xml;version=5.6', 'Cookie' => @cookie }
  end

  def logout
    puts "Logging out ...\n\n"
    self.class.delete('/api/session')
  end
    
  def links
    response = self.class.get('/api/session')
    response['Session']['Link'].each do |link|
      puts link['href']
    end
  end



############################################################################
#####                        RaaSCore starts here                     ######
############################################################################

 
#################################################################################
####         The following functions are used internally and should          ####
####                 not be called from outside this module                  ####
#################################################################################
 

  #this internal function queries the vDCs and returns its HREF

  def vDChref
    response = self.class.get('/api/admin/vdcs/query/')
    vDC = response['QueryResultRecords']['OrgVdcRecord']
    vDChref = vDC['href'][46..81]
    return vDChref
  end
  
  
  #this internal function retrieves all the replications in the vDC 

  def replicationshref
    vDC = vDChref
    response = self.class.get("/api/vdc/#{vDC}/replications")
    replicationshref = [response['References']['Reference']].flatten
    return replicationshref
  end 


  #this internal function issues the test failover action against the VM ID passed 

  def testfailover(replicaURI, replicadetailsname)
  				self.class.default_options[:headers] = {"Accept" => "application/*+xml;version=5.6", "Cookie" => @cookie, "Content-Type" => "application/vnd.vmware.hcs.testFailoverParams+xml"}
      			testFailoverParam = XmlFu.xml("TestFailoverParams" => { 
		     	"@xmlns" => "http://www.vmware.com/vr/v6.0",
		     	"@xmlns:vcloud_v1.5" => "http://www.vmware.com/vcloud/v1.5",
		     	"@name" => "xs:string",
		    	"Synchronize" => " false "
		        })
      			response = self.class.post("/api/vr/replications/#{replicaURI}/action/testFailover",  :body => testFailoverParam)
      			puts "the VM ".green + replicadetailsname + " is being failed over for test".green
      			puts "\n"
  end 


  #this internal function issues the failover action against the VM ID passed 

  def failover(replicaURI, replicadetailsname)
    			self.class.default_options[:headers] = {"Accept" => "application/*+xml;version=5.6", "Cookie" => @cookie, "Content-Type" => "application/vnd.vmware.hcs.failoverParams+xml"}
      			failoverParam = XmlFu.xml("FailoverParams" => { 
		     	"@xmlns" => "http://www.vmware.com/vr/v6.0",
		     	"@xmlns:vcloud_v1.5" => "http://www.vmware.com/vcloud/v1.5",
		     	"@name" => "xs:string",
		        })
      			response = self.class.post("/api/vr/replications/#{replicaURI}/action/failover",  :body => failoverParam)
      			puts "the VM ".green + replicadetailsname + " is being failed over for production usage".green
      			puts "\n"
  end 


  #this internal function cleans up a testfailover against the VM ID passed 

  def testcleanup(replicaURI, replicadetailsname)
  				response = self.class.post("/api/vr/replications/#{replicaURI}/action/testCleanup")
      			puts "the VM ".green + replicadetailsname + " is being cleaned up".green
      			puts "\n"
  end 





#################################################################################
####            The following functions can be used externally.              ####
####        They implement functions that maps the public API calls          ####              
#################################################################################


  #this function queries the peers associated to the DR VPC and
  #it returns an array with the peers URIs, an array of site names
  #and an array of site IDs
  
  def peers
	    vDC = vDChref
        response = self.class.get("/api/vdc/#{vDC}/peers")
        peersarray = [response['References']['Reference']].flatten	  	
	  	peerURI = Array.new
	  	siteName = Array.new
	  	siteID = Array.new
	  	i = 0
		peersarray.each do |peer| 
					peerhref = peer['href']
					peerURI[i] = peerhref[51..124]
					response = self.class.get("/api/vr/peers/#{peerURI[i]}")
					peerinfo = response['Peer']
					siteName[i] = peerinfo['SiteName']
					siteID[i] = peerinfo['SiteUuid']
					i+= 1
		end
		return peerURI, siteName, siteID
  end 


  #this function queries ALL active replications for the DR VPC 
  #it returns an array that contains all replications HREFs
  
  
  def replications(target)
    replicationsarray = replicationshref
    foundVM = false
	vmname = Array.new
    rpo = Array.new 
    replicationState = Array.new
   	quiesceGuestEnabled = Array.new
    paused = Array.new
    currentRpoViolation = Array.new
    testRecoveryState = Array.new
    recoveryState = Array.new
	vmhref = Array.new
	i = 0
	if target == 'ALL'
	    replicationsarray.each do |replica|
	      		replicahref = replica['href']
	    	    replicaURI = replicahref[58..136]
 	     		response = self.class.get("/api/vr/replications/#{replicaURI}")
 	     		replicadetails = response['ReplicationGroup']
 	     		vmname[i] = replicadetails['name']
 	     		rpo[i] = replicadetails['Rpo']
 		   		replicationState[i] = replicadetails['ReplicationState']
 	  			quiesceGuestEnabled[i] = replicadetails['QuiesceGuestEnabled']
  		  		paused[i] = replicadetails['Paused']
    			currentRpoViolation[i] = replicadetails['CurrentRpoViolation']
    			testRecoveryState[i] = replicadetails['TestRecoveryState']
    			recoveryState[i] = replicadetails['RecoveryState']
				vmhref[i] = replicadetails['href']
				foundVM = true
				end #do
		else
				replicationsarray.each do |replica|
	      				replicahref = replica['href']
	    	   			replicaURI = replicahref[58..136]
 	     				response = self.class.get("/api/vr/replications/#{replicaURI}")
 	     				replicadetails = response['ReplicationGroup']
 	   			 		if replicadetails['name'] == target
 	   			 				 vmname[i] = replicadetails['name']
 	     				  		 rpo[i] = replicadetails['Rpo']
 						   		 replicationState[i] = replicadetails['ReplicationState']
 	  							 quiesceGuestEnabled[i] = replicadetails['QuiesceGuestEnabled']
  		  						 paused[i] = replicadetails['Paused']
    							 currentRpoViolation[i] = replicadetails['CurrentRpoViolation']
    							 testRecoveryState[i] = replicadetails['TestRecoveryState']
    				 			 recoveryState[i] = replicadetails['RecoveryState']
								 vmhref[i] = replicadetails['href']
 								 foundVM = true
 						end #if
				end #do
    end #if				
	return foundVM, vmname, rpo, replicationState, quiesceGuestEnabled, paused, currentRpoViolation, testRecoveryState, recoveryState, vmhref
  end

  
  #this function issues the testfailover action against the VM ID passed 

 


  #this function scrolls the array of replications, query the HREFs and search for the VM name
  #if it finds the VM name, it calls the testfailover function to test failover the VM

  def testfailoverVM
    replicationsarray = replicationshref
    puts 'Performing a test failover of VM '.green + $details + '. Please wait.'.green
    puts "\n"
    testfailover = false
    foundVM = false
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['name'] == $details
      		foundVM = true 
      		if replicadetails['TestRecoveryState'] == 'none'
     			if replicadetails['RecoveryState'] == 'notStarted'
      				testfailover = true
      				testfailover(replicaURI, replicadetails['name'])
      			end #if
      		end #if
      end
    end
    return foundVM, testfailover
  end  


  #this function scrolls the array of replications, query the HREFs and search for the VM name
  #if it finds the VM name, it calls the testfailover function to test failover the VM
  
  def failoverVM
    replicationsarray = findreplications
    puts 'Performing the failover of VM '.green + $details + ' for production usage. Please wait.'.green
    puts "\n"
    failover = false
    foundVM = false
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['name'] == $details
      		foundVM = true 
      		if replicadetails['TestRecoveryState'] == 'none'
     			if replicadetails['RecoveryState'] == 'notStarted'
      				failover = true
      				failover(replicaURI, replicadetails['name'])
      			end #if
      		end #if
      end
    end
    return foundVM, failover
  end  



















  #this function scrolls the array of replications and it calls the testfailover function on every VM *Dangerous*

  def testfailoverALL
    replicationsarray = findreplications
    puts 'Performing test failover of all VMs. Please wait.'.green
    puts "\n"
    replicationsarray.each do |replica|
      testfailover = false
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['TestRecoveryState'] == 'none'
      			if replicadetails['RecoveryState'] == 'notStarted'
      				testfailover = true
      				testfailover(replicaURI, replicadetails['name'])
      			end #if
      end #if
      if testfailover == false
       		puts "Sorry, the VM ".red + replicadetails['name'] + " is not in the proper state to test a failover".red
       		puts "\n"
      end 
    end #each do
    puts "\n"
  end  


  #this function scrolls the array of replications, query the HREFs and search for the VM name
  #if it finds the VM name, it calls the testcleanup function to cleanup the test failover for the VM

  def testcleanupVM
    replicationsarray = findreplications
    puts "Performing a testcleanup of VM ".green + $details + '. Please wait.'.green
    puts "\n"
    testcleanup = false
    foundVM = false
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['name'] == $details 
                foundVM = true
  				if replicadetails['TestRecoveryState'] == "complete" or replicadetails['TestRecoveryState'] == "testError" 
      				testcleanup(replicaURI, replicadetails['name'])
      				testcleanup = true
      			else end
      end #if 
    end #each do   
   	if foundVM == false 
   		puts "Sorry, I couldn't not find the VM ".red + $details
   		puts "\n"
   		else
   		if testcleanup == false 
   			puts "Sorry, the VM ".red + $details + " is not in a test failover state that allows a clean up".red
		end 
    end
    puts "\n"
  end
  
  
  #this function scrolls the array of replications and it calls the testcleanup function on every VM 
  
  def testcleanupALL 
    replicationsarray = findreplications
    puts "Performing a testcleanup of ALL VMs. Please wait.".green
    puts "\n"
    replicationsarray.each do |replica|
      testcleanup = false
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['TestRecoveryState'] == "complete"  or replicadetails['TestRecoveryState'] == "testError"
      				testcleanup = true
      				testcleanup(replicaURI, replicadetails['name'])
      end #if 
   	  if testcleanup == false 
      		  puts "Sorry, the VM ".red + replicadetails['name'] + " is not in a test failover state that allows a clean up".red
   			  puts "\n"
	  end
    end #each do   
  end
  
  
  #this function scrolls the array of replications, query the HREFs and search for the VM name
  #if it finds the VM name, it calls the testfailover function to test failover the VM
  
  def failoverVM
    replicationsarray = findreplications
    puts 'Performing the failover of VM '.green + $details + ' for production usage. Please wait.'.green
    puts "\n"
    failover = false
    foundVM = false
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['name'] == $details
      		foundVM = true 
      		if replicadetails['TestRecoveryState'] == 'none'
     			if replicadetails['RecoveryState'] == 'notStarted'
      				failover = true
      				failover(replicaURI, replicadetails['name'])
      			end #if
      		end #if
      end
    end
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
  
  
  #this function scrolls the array of replications and it calls the failover function on every VM *Dangerous*

  def failoverALL
    replicationsarray = findreplications
    puts 'Performing a failover of all VMs for production usage. Please wait.'.green
    puts "\n"
    replicationsarray.each do |replica|
      failover = false
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['TestRecoveryState'] == 'none'
      			if replicadetails['RecoveryState'] == 'notStarted'
      				failover = true
      				failover(replicaURI, replicadetails['name'])
      			end #if
      end #if
      if failover == false
       		puts "Sorry, the VM ".red + replicadetails['name'] + " is not in the proper state to perform a failover".red
       		puts "\n"
      end 
    end #each do
    puts "\n"
  end  
  
  
  
end # class RaaS







