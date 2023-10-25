pipeline {
    options{
      ansiColor('xterm')
    }
    agent { node { label 'Agent-1' } }
    parameters {
        string(name: 'version', defaultValue: '1.0.1', description: 'Which version need to deploy?')
    }

    stages {
       // to call the downstream job(deployment) we need to call it here 
        stage('Deploy') {
            steps {
                echo "Deployment"
                echo "version is ${params.version}"
            }
        }

        stage('init') {
            steps {
                sh """
                cd terraform
                terraform init
                """
        }
    }
        stage('plan') {
            steps {
                sh """
                cd terraform
                terraform plan -var ="app_version = ${params.version}"
                """
           }
        }
     stage('approver') {
            input {
                message "Should we continue?"
                ok "Yes, we should."
                submitter "alice,bob"
                parameters {
                    string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
                }
            }
            steps {
                echo "Hello, ${PERSON}, nice to meet you."
            }
        }

          stage('apply') {
            steps {
                sh """
                cd terraform
                terraform apply -var="app_version=${params.version}"-auto-approve
                """
           }
        }
    }

    post{
        always{
            echo 'cleaning up workspace'
            deleteDir()
        }
    }
}
