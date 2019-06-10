pipeline {
    agent any
    parameters {
        booleanParam(name: 'RUN_JENKINS_PLAYBOOK', defaultValue: false, description: 'Option to run the jenkins ansible playbook')
        booleanParam(name: 'RUN_NEXUS_PLAYBOOK', defaultValue: false, description: 'Option to run the nexus ansible playbook')
        booleanParam(name: 'RUN_SONAR_PLAYBOOK', defaultValue: false, description: 'Option to run the sonar ansible playbook')
        booleanParam(name: 'RUN_FORTIFY_PLAYBOOK', defaultValue: false, description: 'Option to run the fortify ansible playbook')
        booleanParam(name: 'RUN_ARCHIVA_PLAYBOOK', defaultValue: false, description: 'Option to run the archiva ansible playbook')
    }
    stages {
        stage('RUN_NEXUS_PLAYBOOK') {
            when {
                beforeAgent true
                expression { params.RUN_NEXUS_PLAYBOOK == true }
            }
            steps {
                sh 'ansible-playbook -i /var/lib/jenkins/devops_hosts -u ec2-user ansible/playbooks/nexus.yml'
            }
        }
        stage('RUN_SONAR_PLAYBOOK') {
            when {
                beforeAgent true
                expression { params.RUN_SONAR_PLAYBOOK == true }
            }
            steps {
                sh 'ansible-playbook -i /var/lib/jenkins/devops_hosts -u ec2-user ansible/playbooks/sonar.yml'
            }
        }
        stage('RUN_FORTIFY_PLAYBOOK') {
            when {
                beforeAgent true
                expression { params.RUN_FORTIFY_PLAYBOOK == true }
            }
            steps {
                sh 'ansible-playbook -i /var/lib/jenkins/devops_hosts -u ec2-user ansible/playbooks/fortify.yml'
            }
        }
        stage('RUN_ARCHIVA_PLAYBOOK') {
            when {
                beforeAgent true
                expression { params.RUN_ARCHIVA_PLAYBOOK == true }
            }
            steps {
                sh 'ansible-playbook -i /var/lib/jenkins/devops_hosts -u ec2-user ansible/playbooks/archiva.yml'
            }
        }
        stage('RUN_JENKINS_PLAYBOOK') {
            when {
                beforeAgent true
                expression { params.RUN_JENKINS_PLAYBOOK == true }
            }
            steps {
                sh 'ansible-playbook -i /var/lib/jenkins/devops_hosts -u ec2-user ansible/playbooks/jenkins.yml'
            }
        }
    }
}
