#################################################################################
####                           Massimo Re Ferre'                             ####
####                             www.it20.info                               ####
####  RaaSCLI, a tool that allows you to interact with a DRaaS subscription  ####
################################################################################# 

class RaaS
  include HTTParty
  format :xml
    
#################################################################################
####        The following functions are standard functions to login          ####
####                     and logout from the tenant                          ####
####        They can be used to interact generically with vCloud Air         ####
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
  
  
  def initialize(file_path = 'RaaSCLI.yml')
    fail "no file #{file_path}" unless File.exists? file_path
    configuration = YAML.load_file(file_path)
    self.class.basic_auth configuration[:username], configuration[:password]
    self.class.base_uri configuration[:site]
    self.class.default_options[:headers] = { 'Accept' => 'application/*+xml;version=5.6' }
  end

  def login
    response = self.class.post('/api/sessions')
    # setting global cookie var to be used later on
    @cookie = response.headers['set-cookie']
    self.class.default_options[:headers] = { 'Accept' => 'application/*+xml;version=5.6', 'Cookie' => @cookie }
  end

  def logout
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
####         The following methods are used internally and should          ####
####                 not be called from outside this module                  ####
#################################################################################
 

  # This internal method queries the vDCs and returns its HREF

  def vDChref
    response = self.class.get('/api/admin/vdcs/query/')
    vDC = response['QueryResultRecords']['OrgVdcRecord']
    vDChref = vDC['href'][46..81]
    return vDChref
  end
  
  
  # This internal method retrieves all the active replications in the DR VPC
  # It returns an array of HREFs for the replications  

  def replicationshref
    vDC = vDChref
    response = self.class.get("/api/vdc/#{vDC}/replications")
    replicationshref = [response['References']['Reference']].flatten
    return replicationshref
  end 


  # This internal method issues the test failover action against the VM ID passed
  # It doesn't return anything, it just executes the testfailover

  def testfailover(replicaURI)
  				self.class.default_options[:headers] = {"Accept" => "application/*+xml;version=5.6", "Cookie" => @cookie, "Content-Type" => "application/vnd.vmware.hcs.testFailoverParams+xml"}
      			testFailoverParam = XmlFu.xml("TestFailoverParams" => { 
		     	"@xmlns" => "http://www.vmware.com/vr/v6.0",
		     	"@xmlns:vcloud_v1.5" => "http://www.vmware.com/vcloud/v1.5",
		     	"@name" => "xs:string",
		    	"Synchronize" => " false "
		        })
      			response = self.class.post("/api/vr/replications/#{replicaURI}/action/testFailover",  :body => testFailoverParam)
  end 


  # This internal method issues the failover action against the VM ID passed
  # It doesn't return anything, it just executes the failover

  def failover(replicaURI)
    			self.class.default_options[:headers] = {"Accept" => "application/*+xml;version=5.6", "Cookie" => @cookie, "Content-Type" => "application/vnd.vmware.hcs.failoverParams+xml"}
      			failoverParam = XmlFu.xml("FailoverParams" => { 
		     	"@xmlns" => "http://www.vmware.com/vr/v6.0",
		     	"@xmlns:vcloud_v1.5" => "http://www.vmware.com/vcloud/v1.5",
		     	"@name" => "xs:string",
		        })
      			response = self.class.post("/api/vr/replications/#{replicaURI}/action/failover",  :body => failoverParam)
  end 


  # This internal method issues the test cleanup action against the VM ID passed
  # It doesn't return anything, it just executes the testcleanup

  def testcleanup(replicaURI)
  				response = self.class.post("/api/vr/replications/#{replicaURI}/action/testCleanup")
  end 



#################################################################################
####            The following methods can be used externally.              ####
####        They implement functions that maps the public API calls          #### 
#### I'll avoid calling this an SDK for vCloud Air RaaS (but it's an attempt)####             
#################################################################################


  #this method queries the peers associated to the DR VPC and
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
        if peersarray[0] != nil
		peersarray.each do |peer| 
					peerhref = peer['href']
					peerURI[i] = peerhref[51..124]
					response = self.class.get("/api/vr/peers/#{peerURI[i]}")
					peerinfo = response['Peer']
					siteName[i] = peerinfo['SiteName']
					siteID[i] = peerinfo['SiteUuid']
					i+= 1
		end
		end #if != NIL
		return peerURI, siteName, siteID
  end 


  # This method queries active replications for the DR VPC
  # It accept a target as an input. It can be "ALL" or an arbitrary name.
  # If it's an arbitrary name the method will search for a VM with that name
  # It returns a number of arrays that contains the/all replication/s HREFs 
  
  
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
    if replicationsarray[0] != nil 
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
				i+= 1
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
    end #if	replications = ALL 
    end #if != NIL
    return foundVM, vmname, rpo, replicationState, quiesceGuestEnabled, paused, currentRpoViolation, testRecoveryState, recoveryState, vmhref
  end

  
  # This method issues the testfailover action against the VM name passed as input. 
  # This method scrolls the array of replications, query the HREFs and search for the VM name
  # If it finds the VM name, it calls the testfailover method to test failover the VM.
  # It returns two variables. FoundVM is set to true or false depending if the VM was found or not.
  # Testfailover is set to true or false depending if the test failover command was issued or not.

  def testfailoverVM(target)
    replicationsarray = replicationshref
    testfailover = false
    foundVM = false
    if replicationsarray[0] != nil 
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['name'] == target
      		foundVM = true 
      		if replicadetails['TestRecoveryState'] == 'none'
     			if replicadetails['RecoveryState'] == 'notStarted'
      				testfailover = true
      				testfailover(replicaURI)
      			end #if
      		end #if
      end
    end
    end #if != NIL
    return foundVM, testfailover
  end  


  # This method issues the failover action against the VM name passed as input. 
  # This method scrolls the array of replications, query the HREFs and search for the VM name
  # If it finds the VM name, it calls the failover method to failover the VM.
  # It returns two variables. FoundVM is set to true or false depending if the VM was found or not.
  # Failover is set to true or false depending if the failover command was issued or not.
    
  def failoverVM(target)
    replicationsarray = replicationshref
    failover = false
    foundVM = false
    if replicationsarray[0] != nil 
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['name'] == target
      		foundVM = true 
      		if replicadetails['TestRecoveryState'] == 'none'
     			if replicadetails['RecoveryState'] == 'notStarted'
      				failover = true
      				failover(replicaURI)
      			end #if
      		end #if
      end #if
    end #eachdo
    end #If != NIL
    return foundVM, failover
  end  


  # This method issues the test cleanup action against the VM name passed as input. 
  # This method scrolls the array of replications, query the HREFs and search for the VM name
  # If it finds the VM name, it calls the testcleanup function to clean up the test.
  # It returns two variables. FoundVM is set to true or false depending if the VM was found or not.
  # Testcleanup is set to true or false depending if the testcleanup command was issued or not.

  def testcleanupVM(target)
    replicationsarray = replicationshref
    testcleanup = false
    foundVM = false
    if replicationsarray[0] != nil
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      if replicadetails['name'] == target 
                foundVM = true
  				if replicadetails['TestRecoveryState'] == "complete" or replicadetails['TestRecoveryState'] == "testError" 
      				testcleanup(replicaURI)
      				testcleanup = true
      			else end
      end #if 
    end #each do
    end #if != NIL
    return foundVM, testcleanup
  end
 

  # This method issues the testfailover action against ALL VMs. There is no input. 
  # This method scrolls the array of replications and calls the testfailover method to test failover all VMs.
  # It returns two arrays. Vmname contains the name of the VMs.
  # Testfailover contains true or false depending if the test failover command was issued or not for the VMs.
  
 def testfailoverALL
    replicationsarray = replicationshref
    vmname = Array.new
    testfailover = Array.new
    i = 0
    if replicationsarray[0] != nil
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      vmname[i] = replicadetails['name']
      if replicadetails['TestRecoveryState'] == 'none'
      			if replicadetails['RecoveryState'] == 'notStarted'
      				testfailover[i] = true
      				testfailover(replicaURI)
      			else testfailover[i] = false 
      			end 
      else testfailover[i] = false 
      end #if    	
      i+= 1
    end #each do
    end #if != NIL
    return vmname, testfailover
  end  
  

  # This method issues the testcleanup action against ALL VMs. There is no input. 
  # This method scrolls the array of replications and calls the testcleanup method to testcleanup all VMs.
  # It returns two arrays. Vmname contains the name of the VMs.
  # Testcleanup contains true or false depending if the testcleanup command was issued or not for the VMs.  
  
  def testcleanupALL 
    replicationsarray = replicationshref
    vmname = Array.new
    testcleanup = Array.new
    i = 0
    if replicationsarray[0] != nil
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      vmname[i] = replicadetails['name']
      if replicadetails['TestRecoveryState'] == "complete"  or replicadetails['TestRecoveryState'] == "testError"
      				testcleanup[i] = true
      				testcleanup(replicaURI)
      			else testcleanup[i] = false 
      end #if
      i+= 1
    end #each do   
    end #if != NIL
    return vmname, testcleanup 
  end
  
  
  # This method issues the failover action against ALL VMs. There is no input. 
  # This method scrolls the array of replications and calls the failover method to failover all VMs.
  # It returns two arrays. Vmname contains the name of the VMs.
  # Failover contains true or false depending if the failover command was issued or not for the VMs.
  
  def failoverALL
    replicationsarray = replicationshref
    vmname = Array.new
    failover = Array.new
    i = 0
    if replicationsarray[0] != nil
    replicationsarray.each do |replica|
      replicahref = replica['href']
      replicaURI = replicahref[58..136]
      response = self.class.get("/api/vr/replications/#{replicaURI}")
      replicadetails = response['ReplicationGroup']
      vmname[i] = replicadetails['name']
      if replicadetails['TestRecoveryState'] == 'none'
      			if replicadetails['RecoveryState'] == 'notStarted'
      				failover[i] = true
      				failover(replicaURI)
      			else failover[i] = false 
      			end
      else failover[i] = false 
      end #if
      i+= 1
    end #each do
    end #if != NIL
    return vmname, failover
  end  
  
  
  
end # class RaaS







