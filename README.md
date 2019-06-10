
# devops-mgmt
The DaaS Automation Framework provides ADOs a standard DevOps infrastructure. The configuration is customizable and should adapt to the ADO's needs and requirements. At the very minimum, the framework will consist of one Jenkins EC2 instance. The option of creating a SonarQube, Nexus, and Fortify instance is also included.

## How it Works
The "devops-mgmt.yaml" file under /cloudformation is the cloudformation script used to automate everything from one command/run. Parameters can be set to customize the script for the ADOs environment.

The Jenkins ec2 instance uses user-data to clone this repo from a remote source and then run the /setup_scripts/bootstrap.sh script. The bootstrap.sh script setups the volumes, installs ansible, and runs the chosen ansible playbooks. 

ADO teams (with help from the DaaS team) will run the cloudformation script to create the inital framework

## Setup  
### Github
1. Create a GitHub personal access token for the Jenkins service account **Settings > Personal access tokens > Generate new token** and copy down / save the personal access token as you will need to use it again later.
 - **Note:** To set up the ability to push changes to GitHub from your local system, use the `https://` URL for your repository (e.g. `https://github.cms.gov/DaaS/devops-mgmt`) as your remote URL, and when prompted for credentials upon `git push`, use your EUA ID as the username and the Personal Access Token as your password. 
 - Also, before the first time you try to do this, you should open Git Bash and run the following command to make your HTTP POST buffer large enough to push this repo: `git config --global http.postBuffer 524288000` (that "magic number" is just 500 MiB)
 - SSH pushing is not supported as port 22 is not open, so all interaction with CMS GitHub must be over `https`. Your regular EUA password won't work, either, because that wouldn't be proper 2FA. The Personal Access Token resolves this problem.

### Fortify
Some additional manual configurations are required if Fortify is chosen as a component of the DaaS framework. 
- Create an s3 bucket called "daas-fortify-installer"
- Add the Fortify_SCA_and_Apps_Linux.tar.gz
- Add the fortify.license

### AWS Console 
2. Create jenkins-master-key key pair (Used to ssh to jenkins instance). **EC2 > Key Pairs**  
3. Create jenkins-deploy-key key pair (Used to ssh from jenkins to client). **EC2 > Key Pairs**  
4. Create Encryption key to secure param store. Set desired key admin and user (Should be ADO admin for the environment). **IAM > Encryption Keys** 
> When using Sandman, be sure to give the sandman role "sandman-crossacct-role" user access to the key 
5. Determine a password for the Jenkins admin user. This will be stored in the paramstore as **JenkinsAdminPassword**
6. If Nexus will be used, Determine a password for the Nexus admin user. This will be stored in the paramstore as **NexusAdminPassword**
7. If Sonar will be used, Create a temporary token value stored as **SonarQubeToken**. This value will need to be manually updated once the token is manually generated after the inital install of SonarQube. 
8. Create Parameters to be used by the scripts **AWS Systems Manager > Parameter store > Create parameter**
> **Parameters**: JenkinsDeployKey, GithubToken, JenksinAdminPassword, NexusAdminPassword, SonarQubeToken
> **Type**:  SecureString  
> **KMS key source**: My current account  
> **KMS keys ID**: *"choose Encryption key alias created for param store"*  
> **Value**: *Respective values for the two params*

9. Generate the cloudformation script **CloudFormation > Create Stack** :
- Obtain up-to-date script from DaaS team
- Choose to upload the template from file. 
- Name the stack "devops-mgmt-<project-name>". The stack name must begin with "devops-mgmt" to work with the gi stack update.	
- Update the parameters accordingly for the ADO environment.
- Continue until "Create" is an option. Check the radio button to acknowledge IAM resource creation.

10. The cloudforamtion script will begin to create the AWS resources. Under the EC2 Service on the console, search for the whatever the "ProjectName" parameter was set to in the cloudformation script. The jenkins, nexus, and sonar instances should begin to show as initalizing. Once the jenkins instance has started, ssh access should soon be available.  
Using the jenkins-master-key, connect to OpenVPN ssh into the jenkins instance:
`ssh -i <path_to_jenkins-master-key_private_key> ec2-user@<jenkins_private_ip_address>`
Tail the log file to show the progress of the script and ensure no errors occur:
`sudo tail -f /var/log/user-data.log` 

### SonarQube UI
 11. Open a browser and head to 
	 `<sonar_private_ip>:9000`
 12. Login with the deafult credentials
	 > Username: admin
	 > Password: admin 
13. Change the default admin password and store the new password in a secure location.
14.  Generate a token to be used with Jenkins (https://docs.sonarqube.org/display/SONAR/User+Token)
15. Copy the token and store in a secure location

### Jenkins UI
16. Open a browser and head to 
	   `<jenkins_private_ip>:8080`
17. Login with the default credentials
	  > Username: admin
	  > Password: <JenkinsAdminPassword>
18. Add SonarQube token to the Jenkins SonarQube Global configuration **Manage Jenkins** **>** **Global Tool Configuration** 

### Nexus UI
19. Open a browser and head to 
	   `<nexus_private_ip>:8081`
20. Login with the password from the parameter store
	  > Username: admin
	  > Password: <NexusAdminPassword>
21. Change the default admin password and store the new password in a secure location 

## Maintenance  
### Jenkins Jobs
The jenkins instance contains several jobs that can be used to manage the stack
- devops-stack-ansible
	- Runs the ansible playbooks for the chosen devops instances. This is used to update the jenkins, sonar, fortify, and nexus instances.
	- Will run the latest playbooks for the specified branch
- devops-stack-gi-snapshots
	- Creates "gold snapshots" for the specified devops instances. 
	- This will stop the unique services of the instances, take a snapshot with the "gold-image-deploy" tag, and restart the services.
- devops-stack-new-gi-stack
	- Creates a new devops stack using the "gold-image-deploy" snapshots created by the devops-stack-gi-snapshots job.

### Gold Image Stack Update
A new stack should be created once a new RHEL gold image is available. The process to create a new stack is...
- Run the "devops-stack-gi-snapshots" job to create snapshots of the ebs volumes holding the persistent data.
It is important to use this job to create the snapshots. If this job is not used for SonarQube, the build for SonarQube will fail because .my.cfn does not exist
- Run the "devops-stack-new-gi-stack" job to create a new devops stack using the latest gold ami and the latest gold snapshots of the devops ebs volumes.
- Once the new stack is created, ensure everything works as expected and then delete the old devops stack. 
### Updating the Jenkins Admin password
1. Change the admin password in the Jenkins Console.
2. Update the **JenkinsAdminPassword** param in the paramstore to reflect the new updated password.
### Updating the Nexus Admin password
1. Change the admin password through the Nexus UI.
2. Update the **NexusAdminPassword** param in the paramstore to reflect the new updated password.
## Notes
 ### Thirparty Sources:
 - Spring: https://github.com/springframeworkguru/springbootwebapp/search?q=.png&unscoped_q=.png
 - Jenkins: https://github.com/geerlingguy/ansible-role-jenkins
 - Java: https://github.com/geerlingguy/ansible-role-java
 - Apache: https://github.com/geerlingguy/ansible-role-apache
 - SonarQube: https://github.com/Hylke1982/ansible-role-sonar
 - Ansible-Terraform plugin https://nicholasbering.ca/tools/2018/01/08/introducing-terraform-provider-ansible/

- Nexus: https://github.com/savoirfairelinux/ansible-nexus3-oss
> Change made: added ansible resource to update permissions on install directory  
> task: nexus_install.yml  
> - name: Update permissions on nexus install dir
  file:
    dest: "{{ nexus_installation_dir }}/nexus-{{ nexus_version }}"
    owner: "{{ nexus_os_user }}"
    group: "{{ nexus_os_group }}"
    recurse: yes
 
- MySql: https://github.com/geerlingguy/ansible-role-mysql
> Change made: account for SELINUX issue.  
> task: configure.yml  
>  - -name: Change context on error log file  (if configured).
  command: chcon system_u:object_r:mysqld_log_t:s0 "{{ mysql_log_error }}"
  when: mysql_log == "" and mysql_log_error != "" 

- Sonar
> added "/*" to sonar dir move
> added state: link

### Jenkins ALB:
 - *For using jenkins-alb.yaml for Jenkins ->Github webhook integration, whenever you create new jenkins stack, you'll
   have to update this ALB stack CFT with new jenkins Instance ID.

### To Do:
- Docker: https://tech.ticketfly.com/our-journey-to-continuous-delivery-chapter-4-run-jenkins-infrastructure-on-aws-container-service-ef37e0304b95
- Docker Role
- DNS
- S3 terraform state files
- User / SSH management
- Fortify
- Jmeter
- Gradle / Maven bootstrap
- Automated testing framework/s
- HA / CloudWatch
- Please add any more ideas below...
 ### Potential Changes:
- **Ansible Galaxy**: The thirdparty ansible roles have been manually downloaded from Ansible Galaxy. We may want to consider using Ansible Galaxy versioning/pulling instead of manually updating these roles.
- **Docker**: maintain creation of Jenkins, nexus, sonarqube, etc... through containers.
- **RDS for SonarQube running on Docker**
- **OWASP Dependency Checker / ZAP**

### Helpful commands
sudo docker run --rm -v "$(pwd)":/opt/maven -w /opt/maven --net="host" -v "$(pwd)":/root/.m2 maven:3.3.9-jdk-8 mvn -B clean verify