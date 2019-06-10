pipeline {
    agent any
    stages {
    	stage('Create New DevOps Stack') {
        	steps {
        		sh 'ansible-playbook -u ec2-user ./ansible/playbooks/cloudformation/daas-stack-update.yml -e "jenkins_home=/var/lib/jenkins cloudformation_state=present"'
        	}
    	}
    }
}