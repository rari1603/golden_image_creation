pipeline {
    agent any

    environment {
        PACKER_VARS       = 'openstack.pkrvars.hcl'
        PACKER_FILE       = 'openstack.pkr.hcl'
        IMAGE_BASE_NAME   = 'patched-rhel9.2'
        TIMESTAMP         = "${new Date().format('yyyyMMddHHmmss')}"
        IMAGE_NAME        = "${IMAGE_BASE_NAME}-${TIMESTAMP}"
        LOCAL_IMAGE_PATH  = "/home/${IMAGE_BASE_NAME}-${TIMESTAMP}.qcow2"
        VENV_DIR          = "/var/lib/jenkins/venv"
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

        stage('Cleanup Existing Image') {
            steps {
                script {
                    sh """
                        source ${VENV_DIR}/bin/activate
                        packer build \
                            -only=cleanup-existing-image.null.cleanup \
                            -var image_name=${IMAGE_NAME} \
                            -var-file=${PACKER_VARS} \
                            ${PACKER_FILE}
                    """
                }
            }
        }

        stage('Build Image with Packer') {
            steps {
                script {
                    sh """
                        source ${VENV_DIR}/bin/activate
                        packer build \
                            -only=rhel9.2-b2b-image.openstack.rhel_image \
                            -var image_name=${IMAGE_NAME} \
                            -var-file=${PACKER_VARS} \
                            ${PACKER_FILE}
                    """
                }
            }
        }

        stage('Save Image Locally') {
            steps {
                script {
                    sh """
                        source ${VENV_DIR}/bin/activate
                        openstack image save ${IMAGE_NAME} --file ${LOCAL_IMAGE_PATH}
                    """
                }
            }
        }

        stage('Archive Image') {
            steps {
                archiveArtifacts artifacts: "${LOCAL_IMAGE_PATH}", fingerprint: true
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
