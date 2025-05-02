pipeline {
    agent any

    environment {
        PACKER_VARS = 'openstack.pkrvars.hcl'
        PACKER_FILE = 'openstack.pkr.hcl'
        IMAGE_NAME  = 'patched-rhel9.2'
        IMAGE_TIMESTAMP = '20060102150405'
        LOCAL_IMAGE_PATH = "/var/lib/jenkins/workspace/goldenimage/${IMAGE_NAME}-${IMAGE_TIMESTAMP}.qcow2"
        VENV_DIR = "/var/lib/jenkins/venv"
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
                    echo 'Checking if the image exists...'
                    sh 'pwd' // Print the current working directory

                    // FIXED LINE BELOW — wrapped in full shell block
                    sh '''
                        if [ -d /var/lib/jenkins/workspace/goldenimage ]; then
                            ls -l /var/lib/jenkins/workspace/goldenimage/
                        else
                            echo "Directory not found"
                        fi
                    '''
                }
            }
        }

        stage('Archive Image') {
            steps {
                script {
                    echo "Archiving the image from ${LOCAL_IMAGE_PATH}..."
                    archiveArtifacts artifacts: "${LOCAL_IMAGE_PATH}", fingerprint: true
                }
            }
        }

        stage('Upload Image to Another OpenStack Environment') {
            steps {
                script {
                    def imageFile = "${LOCAL_IMAGE_PATH}"
                    def imageName = "${IMAGE_NAME}-${IMAGE_TIMESTAMP}"

                    sh """
                        echo "Uploading image '${imageName}' to the destination OpenStack..."
                        source ${VENV_DIR}/bin/activate
                        
                        if [ ! -f /var/lib/jenkins/workspace/goldenimage/openstack.env ]; then
                            echo "ERROR: Missing openstack.env file with destination cloud credentials!"
                            exit 1
                        fi

                        set -a
                        source /var/lib/jenkins/workspace/goldenimage/openstack.env
                        set +a

                        openstack token issue || { echo "Authentication failed"; exit 1; }

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
            cleanWs()
        }
        failure {
            echo "Build failed!"
        }
    }
}
