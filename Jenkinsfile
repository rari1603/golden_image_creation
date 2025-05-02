pipeline {
    agent any
 
    environment {
        PACKER_VARS = 'openstack.pkrvars.hcl'
        PACKER_FILE = 'openstack.pkr.hcl'
        IMAGE_NAME  = 'patched-rhel9.2'
        LOCAL_IMAGE_PATH = "/home/${IMAGE_NAME}.qcow2"  // Corrected the file path
        VENV_DIR = "/var/lib/jenkins/venv" // Path for virtual environment
    }
 
    stages {
        stage('Clone Repo') {
            steps {
                // Clone the Git repository containing the Packer files
                git branch: 'main', credentialsId: '03', url: 'https://github.com/rari1603/golden_image_creation.git'
            }
        }
 
        stage('Install Dependencies') {
            steps {
                script {
                    // Create a virtual environment
                    sh """
                        python3.9 -m venv ${VENV_DIR}
                    """
 
                    // Activate the virtual environment, upgrade pip, and install python-openstackclient
                    sh """
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
                    // Save the image locally, assuming the image is stored in the current directory
                    sh """
                        cp ${IMAGE_NAME}.qcow2 ${LOCAL_IMAGE_PATH}
                    """
                }
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
