pipeline {
    agent any
    parameters {
        string(name: 'BLUE_STACK_NAME', defaultValue: '', description: 'Provide the name of the new stack to update the alb target groups')
    }
    stages {
        stage('UPDATE TARGET GROUPS') {
            steps {
            	sh "ansible-playbook -u ec2-user ./ansible/playbooks/update-listeners.yml -e \"stack_name=${params.BLUE_STACK_NAME}\""
            }
        }
    }
    post {
        always { 
            cleanWs()
        }
    }
}