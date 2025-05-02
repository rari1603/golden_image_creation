pipeline {
    agent any

    environment {
        TIMESTAMP = sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim()  // Updated to avoid special characters
        IMAGE_NAME = "patched-rhel9.2-${env.TIMESTAMP}.qcow2"
        GITHUB_REPO = 'https://github.com/rari1603/golden_image_creation.git' 
        GITHUB_BRANCH = 'main'  
        VENV_DIR = 'venv'  // Define the virtual environment directory here
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', credentialsId: '03', url: 'https://github.com/rari1603/golden_image_creation.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    sh """
                        python3.9 -m venv ${VENV_DIR}
                        source ${VENV_DIR}/bin/activate
                        pip install --upgrade pip
                        pip install python-openstackclient
                    """
                }
            }
        }

        stage('Build Image with Packer - Cleanup') {
            steps {
                script {
                    // Run the first Packer build command for cleanup
                    sh """
                        source ${VENV_DIR}/bin/activate
                        packer build -only=cleanup-existing-image.null.cleanup -var-file=${PACKER_VARS} ${PACKER_FILE}
                    """
                }
            }
        }

        stage('Build Image with Packer - RHEL Image') {
            steps {
                script {
                    // Run the second Packer build command for RHEL image
                    sh """
                        source ${VENV_DIR}/bin/activate
                        packer build -only=rhel9.2-b2b-image.openstack.rhel_image -var-file=${PACKER_VARS} ${PACKER_FILE}
                    """
                }
            }
        }

        stage('Save Image Locally') {
            steps {
                script {
                    // Save the image locally
                    sh """
                        cp ${IMAGE_NAME} ${LOCAL_IMAGE_PATH}
                    """
                }
            }
        }

        stage('Verify Image Exists') {
            steps {
                script {
                    def fileExists = fileExists("${env.LOCAL_IMAGE_PATH}")
                    if (!fileExists) {
                        error "Image file ${env.LOCAL_IMAGE_PATH} not found! Skipping upload."
                    } else {
                        sh "ls -lh ${env.LOCAL_IMAGE_PATH}"
                    }
                }
            }
        }

        stage('Upload to OpenStack') {
            when {
                expression {
                    fileExists("${env.LOCAL_IMAGE_PATH}")
                }
            }
            steps {
                sh """
                    echo 'Uploading image to OpenStack...'
                    openstack image create --disk-format qcow2 --container-format bare --file ${env.LOCAL_IMAGE_PATH} ${env.IMAGE_NAME}
                """
            }
        }

        stage('Archive Image') {
            steps {
                // Archive the saved image as an artifact for future use or download
                archiveArtifacts artifacts: "${LOCAL_IMAGE_PATH}", fingerprint: true
            }
        }
    }

    post {
        always {
            echo "Build process completed."
            cleanWs() // Clean up workspace after the build
        }
        failure {
            echo "Build failed!"
        }
    }
}
