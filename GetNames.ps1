#region capture Calm variables
   $appName= "@@{calm_application_name}@@" #this is how we named our
                                                  #application instance in calm
   $hostCount = @@{HOST_COUNT}@@ #this is used to keep track of how many VMs we are provisioning
   $dnsZone = "@@{DOMAIN}@@" #this is used to lookup hostnames
  
#endregion

#region initialize other variables
   $userInput = $appName.Substring(0,4).ToUpper() #this generates a 4 character
                                #uppercase string based on the application name
#initilize the environment variable
	$environment = $null							
	switch ("@@{ENVIRONMENT}@@") {
	    "Production" { $environment = "P"; break }
		"Staging" { $environment = "S"; break }
		"Testing" { $environment = "T"; break }
		default {"The chosen environment didn't match any of the following:`
		         Production`
				 Staging`
				 Testing"; break}
	}
	    
#endregion

#region define unique hostname

$i = [int]1 # index for the next host to check
$next = [int]1 # this is used to continue from where we found the first occurence to avoid starting over from the beginin
for ($c = 1; $c -le $hostCount; $c++) {
   
   Do { #test hostnames until one which is not already registered in DNS is
                                                                         #found
       $index = '{0:D2}' -f $next #format our numerical index with 2 digits
                                                         #(it becomes a string)
       $hostname = '{0}-Co-V-{1}-{2}' -f $environment,$userInput,$index #build our hostname
                           #based on the application name trigram and our index
       $fqdn = '{0}.{1}' -f $hostname,$dnsZone #build the fqdn to lookup based
                                              #on the hostname and the DNS zone
       $found = Resolve-DnsName $fqdn -ErrorAction SilentlyContinue #see if our
                                         #hostname is registered in DNS already
       if (!$found) { #hostname was not registered in DNS
           $Error.Clear()
           $node = "NODE{0}_NAME" -f $c
           Write-Host "$node=$hostname"
           #increment our next host to check
           ++$next
           break
       }
       ++$next #increment our next host to check
       ++$i #increment our numerical counter
       
   } While ($i -le 99) #we break out only when the fqdn is not found or when we
                                                   #run out of numerical digits

   if ($i -gt 99) {
       Throw "[ERROR] We ran out of digits to generate a unique hostname!"
   }

}

#endregion

