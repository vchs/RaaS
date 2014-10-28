<html>

<head>
<meta http-equiv="Content-Language" content="en-us">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
</head>

<body>

<p>
####<br>
####&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
Massimo Re Ferre' <br>
####&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="http://www.it20.info">www.it20.info</a>&nbsp;&nbsp;&nbsp; <br>
####&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
RaaSCLI, a tool that allows you to interact with a DRaaS subscription&nbsp; <br>
####<br>
<br>
This tool has been developed mostly as a personal exercise. <br>
<br>
It allows users with a proper vCloud Air DR subscription to interact with the 
service programmatically. <br>
<br>
Once installed (see below), users can call the RaaSCLI command line. It accepts 
a number of different <br>
inputs. Just run RaaSCLI to have hints on usage.<br>
<br>
This is the output on my laptop:<br>
<br>
Usage: /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI operation [option1] 
[option2]<br>
<br>
operations: peers|replications|testfailover|testcleanup|failover<br>
<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI peers<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI replications ALL<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI replications &lt;VM 
name&gt;<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI testfailover &lt;VM 
name&gt;<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI testfailover ALL<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI testcleanup &lt;VM name&gt;<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI testcleanup ALL<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI failover &lt;VM name&gt;<br>
e.g. /Users/mreferre/.rvm/gems/ruby-1.9.3-p484/bin/RaaSCLI failover ALL<br>
<br>
<br>
####<br>
####&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
Important:&nbsp;&nbsp; <br>
####&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
the program requires a file called RaaSCLI.yml in the working dir <br>
####
<br>
<br>
The file contains the parameters to connect to the DR VPC you want to interact 
with. <br>
<br>
The format of the file MUST be as follows: <br>
<br>
:username: email@domain@OrgName<br>
:password: password<br>
:site: https://vcd-url<br>
<br>
You can get those values from the vCloud Air portal pointing to the DR VPC. If 
this file is not in the working directory<br>
(or the values are not correct) the program will abort. <br>
<br>
<br>
<b>Use cases: </b><br>
<br>
- interacting with the service via CLI manually<br>
<br>
- leveraging the CLI from some sort of higher level automation and orchestration 
tools (e.g. vCO or SRM).<br>
<br>
More in general, the program is structured to have a &quot;RaaScore&quot; module that 
wraps the most common DR REST APIs. <br>
I try to refrain calling it a &quot;DR SDK&quot; but, done right, it could probably be 
something like that. There is then a &quot;RaaSmain&quot; module that consumes<br>
constructs in RaaScore and manage the user interaction. RaaSCLI is nothing more 
than a CLI wrapper around RaaScore.<br>
<br>
The idea is that one could take RaaScore and build (e.g.) a Sinatra application 
on top of it. <br>
<br>
<br>
<b>Known limitations (ver 0.0.4):</b><br>
<br>
- I have only tested the tool with very few VMs. It is only supposed to work 
with up to 25 VMs <br>
because I am not paging through the 25 defaults entry per pages in the REST 
queries I run (e.g. GET replications)<br>
<br>
- At the moment the failover ALL / testfailover ALL and / testcleanup ALL runs 
sequentially on all the VMs per the order <br>
of the response against the REST APIs. In other words the VMs will failover / 
testfailover / cleanup in an unforced order.<br>
I am evaluating creating a better logic on the order against which we run those 
commands (e.g. leveraging tags). Feedbacks are welcome.<br>
<br>
<br>
<b>Setup:</b><br>
<br>
I have tested the program with Ruby 1.9.3. I haven't tested it with any other 
Ruby version. <br>
<br>
if you are using Ruby already and are familiar with it, getting the program 
setup could be as easy as running: <br>
<br>
&quot;gem install RaaS&quot; <br>
<br>
If you are new to Ruby, I have tested these steps (http://tecadmin.net/install-ruby-1-9-3-or-multiple-ruby-verson-on-centos-6-3-using-rvm/)
<br>
on a CentOS 6.4 64 bit VM on vCloud Air and they worked just fine. </p>
<p>
At the 
end, you still need to install the CLI by running &quot;gem install RaaS&quot;.<br>
<br>
<br>
<b>Warning: </b><br>
<br>
Please use the tool at your own risk. There are some commands (e.g. &quot;RaaSCLI 
peers&quot; or &quot;RaaSCLI replications ALL&quot;) that are harmless <br>
as they are mostly read-only. However there are other commands (e.g. &quot;RaaSCLI 
failover ALL&quot;) that could be potentially dangerous in a production <br>
environment. Use with cautious. <br>
<br>
<br>
<b>License</b>: Apache Licensing version 2</p>

</body>

</html>
