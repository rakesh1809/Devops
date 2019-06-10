pipeline {
    agent { label 'chefInspec' }
    parameters {
        booleanParam(name: 'RUN_APP_SCAN', defaultValue: true, description: 'Option, Run APP Scan')
        booleanParam(name: 'RUN_OS_SCAN', defaultValue: false, description: 'Option, Run OS Scan')
    }
    stages {

        stage('RUN_SCAN') {
            when {
                beforeAgent true
                expression { params.RUN_APP_SCAN == true || params.RUN_OS_SCAN == true}
            }
            steps {
                sh 'ansible-playbook -i /var/lib/jenkins/devops_hosts $WORKSPACE/ansible/playbooks/inspec-scan.yml -e "ansible_ssh_user=ec2-user RUN_APP_SCAN=$RUN_APP_SCAN RUN_OS_SCAN=$RUN_OS_SCAN"'
                sh 'aws s3 cp ansible/playbooks/inspec.html s3://daas-ansible-baba/inspec.html'
                archiveArtifacts 'ansible/playbooks/inspec.html'
            }
            post {
            success {
              // publish html
              publishHTML target: [allowMissing: false,alwaysLinkToLastBuild: false,keepAll: true,reportDir: 'ansible/files',reportFiles: 'inspec.html',reportName: 'InspecScanReport'
                ]
            }
          }            
        }

    }
}