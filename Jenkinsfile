pipeline {
    agent { node { label 'Agent-1' } }
    stages {
       // to call the downstream job(deployment) we need to call it here 
        stage('Deploy') {
            steps {
                echo "Deployment"
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