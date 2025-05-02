pipeline {
    agent any
    environment {
        TIMESTAMP = sh(script: "date +%Y%m%d", returnStdout: true).trim()
        IMAGE_NAME = "patched-rhel9.2-${env.TIMESTAMP}.qcow2"
        GITHUB_REPO = 'https://github.com/rari1603/golden_image_creation.git' // Replace with your GitHub repo URL
        GITHUB_BRANCH = 'main'  // Replace with your desired branch
    }

    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: '04', url: "${env.GITHUB_REPO}", branch: "${env.GITHUB_BRANCH}"
            }
        }

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Step 1: Cleanup Existing Image') {
            steps {
                sh '''
                    echo "Running cleanup stage..."
                    packer build -only=cleanup-existing-image.null.cleanup -var-file=${VAR_FILE} ${HCL_FILE}
                '''
            }
        }

        stage('Step 2: Build New Image') {
            steps {
                sh '''
                    echo "Running image build stage..."
                    packer build -only=rhel9.2-b2b-image.openstack.rhel_image -var-file=${VAR_FILE} ${HCL_FILE}
                '''
            }
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
