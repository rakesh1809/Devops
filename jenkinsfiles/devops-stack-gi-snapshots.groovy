pipeline {
    agent any
    parameters {
        booleanParam(name: 'CREATE_NEXUS_SNAPSHOT', defaultValue: false, description: 'Option to create a gold snapshot of the existing nexus ebs volume')
        booleanParam(name: 'CREATE_SONAR_SNAPSHOT', defaultValue: false, description: 'Option to create a gold snapshot of the existing sonar ebs volume')
        booleanParam(name: 'CREATE_FORTIFY_SNAPSHOT', defaultValue: false, description: 'Option to create a gold snapshot of the existing fortify ebs volume')
        booleanParam(name: 'CREATE_ARCHIVA_SNAPSHOT', defaultValue: false, description: 'Option to create a gold snapshot of the existing archiva ebs volume')
        booleanParam(name: 'CREATE_JENKINS_SNAPSHOT', defaultValue: false, description: 'Option to create a gold snapshot of the existing jenkins ebs volume')
    }
    stages {
        stage('CREATE_NEXUS_SNAPSHOT') {
        	when {
        		beforeAgent true
        		expression { params.CREATE_NEXUS_SNAPSHOT == true }
        	}
            steps {
            	sh 'sh /var/lib/jenkins/devops_scripts/nexus_gold_snapshot_creation.sh'
            }
        }
        stage('CREATE_SONAR_SNAPSHOT') {
            when {
                beforeAgent true
                expression { params.CREATE_SONAR_SNAPSHOT == true }
            }
            steps {
                sh 'sh /var/lib/jenkins/devops_scripts/sonar_gold_snapshot_creation.sh'
            }
        }
        stage('CREATE_FORTIFY_SNAPSHOT') {
            when {
                beforeAgent true
                expression { params.CREATE_FORTIFY_SNAPSHOT == true }
            }
            steps {
                sh 'sh /var/lib/jenkins/devops_scripts/fortify_gold_snapshot_creation.sh'
            }
        }
        stage('CREATE_ARCHIVA_SNAPSHOT') {
            when {
                beforeAgent true
                expression { params.CREATE_ARCHIVA_SNAPSHOT == true }
            }
            steps {
                sh 'sh /var/lib/jenkins/devops_scripts/archiva_gold_snapshot_creation.sh'
            }
        }
        stage('CREATE_JENKINS_SNAPSHOT') {
            when {
                beforeAgent true
                expression { params.CREATE_JENKINS_SNAPSHOT == true }
            }
            steps {
                sh 'sudo sh /var/lib/jenkins/devops_scripts/jenkins_gold_snapshot_creation.sh &'
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
