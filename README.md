# llm
LLM repository

To use :
Replace AWS account ID and keys as well as account number in the terraform/provider.tf
OpenAI key in settings.php will also need to be replaced if the free one provided does not provide enough queries/day. 

How it works :
The ci-cd yaml file is called by Github Actions on merge. 
Terraform is used to spin up the AWS environment. 
To destroy the AWS environment immediately after you can run the destroy shell script in the terraform directory as provided. 

What it does :
Creates a AWS VPC with everything in it. 
It creates a mysql database.
It creates a loadbalancer to handle queries. 
Build a docker container on the app server with the LLM environment. 
Fire up the docker container which connects to the database and gets called by the load balancer. 
The application uses a PHP front end to chatgpt 3.5 turbo with a custom personality for answering queries (.e. a pet dog). All answers will be in doggie language. 
Since it uses the OpenAI API you can point it to a local LLM running on AWS and avoid the OpenAI costs. 

For improvements :
Use Github secrets instead of everything in text in the repo (example commented out in the github actions file for reference). 
Increase security (it currently has none) by turning on SELinux, adding rate limiters etc. 
Allow updates through actions instead of terraform only and environment teardowns - use a bastion host.
Use RDS for database with multi AZ (example provioded in terraform main.tf.bak file). 
Block code execution and enable the sandbox model for LLM callouts. 
This is a quick and dirty POC. **Do not use for production**.
