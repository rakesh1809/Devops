#! /usr/bin/sh
set -e

# Set variables based on arguments
CREATE_NEXUS=$1
CREATE_SONAR=$2
CREATE_FORTIFY=$3
CREATE_INSPEC=$4
CREATE_ARCHIVA=$5
# JENKINS_EFS=$5
USE_JENKINS_SNAPSHOT=$6
VPC_NAME=$7
AWS_REGION=$8
PROJECT_NAME=$9
GITHUB_UN=${10}
GITHUB_TOKEN=${11}
GITHUB_REPO=${12}
GITHUB_BRANCH=${13}
AWS_STACK_NAME=${14}
FRAMEWORK_STACK_NAME=${15}
JENKINS_HOME="/var/lib/jenkins"

# Determine the corerect location for aws command
if [ -f /bin/aws ]; then
	AWSCMD=/bin/aws
else
	AWSCMD=/usr/local/bin/aws
fi

# Create the Jenkins home dir
mkdir $JENKINS_HOME

# Setup EFS if chosen
# if [ "$JENKINS_EFS" != "false" ]; then
# 	#Setup EFS volume
# 	JENKINS_EFS_IP=`$AWSCMD efs describe-mount-targets --region $AWS_REGION --file-system-id $JENKINS_EFS --query "MountTargets[*].IpAddress" --output=text`
# 	yum install -y nfs-utils;
# 	mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $JENKINS_EFS_IP:/ /var/lib/jenkins;
# 	cp /etc/fstab /etc/fstab.orig;
# 	echo "$JENKINS_EFS_IP:/ /var/lib/jenkins nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0" >> /etc/fstab;
# 	mount -a;
# fi

# Setup EBS volume
if [ "$USE_JENKINS_SNAPSHOT" != "true" ]; then
  mkfs.xfs /dev/xvdh -L JENKINS
fi
mount /dev/xvdh $JENKINS_HOME;
cp /etc/fstab /etc/fstab.orig;
echo "LABEL=JENKINS                           $JENKINS_HOME   xfs    defaults,noatime 0 2" >> /etc/fstab;
mount -a;

# Create Anisble variable file
CFN_VARS_PATH="$JENKINS_HOME/cfn_generated_vars.yml"
echo "---" > $CFN_VARS_PATH
echo "awscmd: $AWSCMD" >> $CFN_VARS_PATH
echo "create_nexus: $CREATE_NEXUS" >> $CFN_VARS_PATH
echo "create_sonar: $CREATE_SONAR" >> $CFN_VARS_PATH
echo "create_fortify: $CREATE_FORTIFY" >> $CFN_VARS_PATH
echo "create_archiva: $CREATE_ARCHIVA" >> $CFN_VARS_PATH
echo "create_inspec: $CREATE_INSPEC" >> $CFN_VARS_PATH
echo "jenkins_home: $JENKINS_HOME" >> $CFN_VARS_PATH
echo "vpc_name: $VPC_NAME" >> $CFN_VARS_PATH
echo "aws_region: $AWS_REGION" >> $CFN_VARS_PATH
echo "aws_stack_name: $AWS_STACK_NAME" >> $CFN_VARS_PATH
echo "project_name: $PROJECT_NAME" >> $CFN_VARS_PATH
echo "github_un: $GITHUB_UN" >> $CFN_VARS_PATH
echo "github_token: $GITHUB_TOKEN" >> $CFN_VARS_PATH
echo "github_repo: $GITHUB_REPO" >> $CFN_VARS_PATH
echo "github_branch: $GITHUB_BRANCH" >> $CFN_VARS_PATH
echo "framework_stack_name: $FRAMEWORK_STACK_NAME" >> $CFN_VARS_PATH

# Install ansible
echo "setting up ansible";
yum install ansible -y;

# Set permissions for ec2 and jenkins
chmod 700 /home/ec2-user/.ssh;
chmod 600 /home/ec2-user/.ssh/id_rsa;
chown -R ec2-user:ec2-user /home/ec2-user;
echo "jenkins        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# Wait for the stack status to be complete. This is needed to ensure the stack outputs are set.
stack_result==""
i=0
until [ $stack_result == "CREATE_COMPLETE" ] || [ $i -gt 100 ]
do
        echo "Waiting for stack creation"
        stack_result=`$AWSCMD cloudformation describe-stacks --region $AWS_REGION --stack-name $AWS_STACK_NAME --query 'Stacks[0].StackStatus' --output text`
        i=$(( i+1 ))
done

# Create host list for playbooks and run playbooks
JENKINS_IP=`$AWSCMD cloudformation describe-stacks --region $AWS_REGION --stack-name $AWS_STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==\`JenkinsIP\`].OutputValue' --output text`
echo "[jenkins]" > /home/ec2-user/devops_hosts;
echo "$JENKINS_IP" >> /home/ec2-user/devops_hosts;

if [ "$CREATE_NEXUS" = "true" ]; then
	NEXUS_IP=`$AWSCMD cloudformation describe-stacks --region $AWS_REGION --stack-name $AWS_STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==\`NexusIP\`].OutputValue' --output text`
	echo "[nexus]" >> /home/ec2-user/devops_hosts;
	echo "$NEXUS_IP" >> /home/ec2-user/devops_hosts;
	su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/nexus.yml &';
fi
if [ "$CREATE_SONAR" = "true" ]; then
	SONAR_IP=`$AWSCMD cloudformation describe-stacks --region $AWS_REGION --stack-name $AWS_STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==\`SonarIP\`].OutputValue' --output text`
	echo "[sonar]" >> /home/ec2-user/devops_hosts;
	echo "$SONAR_IP" >> /home/ec2-user/devops_hosts;
	su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/sonar.yml &';
fi
if [ $CREATE_FORTIFY = "true" ]; then
	FORTIFY_IP=`$AWSCMD cloudformation describe-stacks --region $AWS_REGION --stack-name $AWS_STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==\`FortifyIP\`].OutputValue' --output text`
	echo "[fortify]" >> /home/ec2-user/devops_hosts;
	echo "$FORTIFY_IP" >> /home/ec2-user/devops_hosts;
	su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/fortify.yml &';
fi
if [ $CREATE_INSPEC = "true" ]; then
	echo "Name: $PROJECT_NAME-$VPC_NAME-devops-inspec";
	INSPEC_IP=`$AWSCMD cloudformation describe-stacks --region $AWS_REGION --stack-name $AWS_STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==\`InspecIP\`].OutputValue' --output text`
	echo "[inspec]" >> /home/ec2-user/devops_hosts;
	echo "$INSPEC_IP" >> /home/ec2-user/devops_hosts;
	su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/inspec.yml &';
fi
if [ $CREATE_ARCHIVA = "true" ]; then
	ARCHIVA_IP=`$AWSCMD cloudformation describe-stacks --region $AWS_REGION --stack-name $AWS_STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==\`ArchivaIP\`].OutputValue' --output text`
	echo "[archiva]" >> /home/ec2-user/devops_hosts;
	echo "$ARCHIVA_IP" >> /home/ec2-user/devops_hosts;
	su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/archiva.yml &';
fi
ansible-playbook -i /home/ec2-user/devops_hosts -u ec2-user /home/ec2-user/devops-mgmt/ansible/playbooks/jenkins.yml;
