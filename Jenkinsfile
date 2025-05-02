pipeline {
    agent any
 
    environment {
        PACKER_VARS = 'openstack.pkrvars.hcl'
        PACKER_FILE = 'openstack.pkr.hcl'
        IMAGE_NAME  = 'patched-rhel9.2'
        LOCAL_IMAGE_PATH = "workspace/goldenimage/${IMAGE_NAME}.qcow2"  // Correct the path relative to Jenkins workspace
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

        stage('Check Image Directory') {
            steps {
                script {
                    // Check if the image exists in Jenkins workspace
                    sh 'echo "Checking if the image exists..."'
                    sh 'ls -l /var/lib/jenkins/workspace/goldenimage/' // List contents of the workspace
                }
            }
        }

        stage('Archive Image') {
            steps {
                script {
                    echo "Archiving the image from ${LOCAL_IMAGE_PATH}..."
                    // Archive the saved image as an artifact for future use or download
                    sh """
                        if [ -f "${LOCAL_IMAGE_PATH}" ]; then
                            echo "Image found, archiving..."
                            archiveArtifacts artifacts: "${LOCAL_IMAGE_PATH}", fingerprint: true
                        else
                            echo "Image not found at ${LOCAL_IMAGE_PATH}, skipping archive."
                        fi
                    """
                }
            }
        }

        stage('Upload Image to Another OpenStack Environment') {
            steps {
                script {
                    def imageFile = "${LOCAL_IMAGE_PATH}"  // The qcow2 file created by Packer
                    def imageName = "${IMAGE_NAME}"  // Image name (e.g., "patched-rhel9.2-<timestamp>")

                    sh """
                        echo "Uploading image '${imageName}' to the destination OpenStack..."

                        # Activate Python virtual environment
                        source ${VENV_DIR}/bin/activate

                        # Load destination OpenStack environment variables from the openstack.env file
                        if [ ! -f openstack.env ]; then
                            echo "ERROR: Missing openstack.env file with destination cloud credentials!"
                            exit 1
                        fi

                        set -a
                        source openstack.env
                        set +a

                        echo "Validating OpenStack environment..."
                        openstack token issue || { echo "Authentication failed"; exit 1; }

                        # Upload the image to the destination OpenStack using 'openstack image create'
                        echo "Uploading image ${imageName} to the destination OpenStack..."
                        openstack image create \\
                            --disk-format qcow2 \\
                            --container-format bare \\
                            --public \\
                            --file "${imageFile}" \\
                            "${imageName}"

                        echo "Upload complete."
                    """
                }
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
