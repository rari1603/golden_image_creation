pipeline {
    agent any
    environment {
        TIMESTAMP = sh(script: "date +%Y%m%d", returnStdout: true).trim()
        IMAGE_NAME = "patched-rhel9.2-${env.TIMESTAMP}.qcow2"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Run Packer Build') {
            steps {
                sh '''
                    echo "Running packer build..."
                    packer build -var-file=openstack.pkrvars.hcl openstack.pkr.hcl
                '''
            }
        }

        stage('Verify Image Exists') {
            steps {
                script {
                    def fileExists = fileExists("${env.IMAGE_NAME}")
                    if (!fileExists) {
                        error "Image file ${env.IMAGE_NAME} not found! Skipping upload."
                    } else {
                        sh "ls -lh ${env.IMAGE_NAME}"
                    }
                }
            }
        }

        stage('Upload to OpenStack') {
            when {
                expression {
                    fileExists("${env.IMAGE_NAME}")
                }
            }
            steps {
                sh """
                    echo 'Uploading image to OpenStack...'
                    openstack image create --disk-format qcow2 --container-format bare --file ${env.IMAGE_NAME} ${env.IMAGE_NAME}
                """
            }
        }
    }

    post {
        always {
            echo 'Build process completed.'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
