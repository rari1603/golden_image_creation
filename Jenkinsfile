pipeline {
    agent any

    environment {
        PACKER_VARS = 'openstack.pkrvars.hcl'
        PACKER_FILE = 'openstack.pkr.hcl'
        IMAGE_NAME  = 'patched-rhel9.2'
        VENV_DIR = "/var/lib/jenkins/venv"
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', credentialsId: '03', url: 'https://github.com/rari1603/golden_image_creation.git'
            }
        }

        stage('Generate Timestamp') {
            steps {
                script {
                    env.IMAGE_TIMESTAMP = sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim()
                    env.LOCAL_IMAGE_PATH = "/var/lib/jenkins/workspace/goldenimage/${env.IMAGE_NAME}-${env.IMAGE_TIMESTAMP}.qcow2"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh """
                    python3.9 -m venv ${VENV_DIR}
                    source ${VENV_DIR}/bin/activate && \
                    pip install --upgrade pip && \
                    pip install python-openstackclient
                """
            }
        }

        stage('Build Image - Cleanup') {
            steps {
                sh """
                    source ${VENV_DIR}/bin/activate && \
                    packer build -only=cleanup-existing-image.null.cleanup -var-file=${PACKER_VARS} ${PACKER_FILE}
                """
            }
        }

        stage('Build Image - RHEL Image') {
            steps {
                sh """
                    source ${VENV_DIR}/bin/activate && \
                    packer build -only=rhel9.2-b2b-image.openstack.rhel_image -var-file=${PACKER_VARS} ${PACKER_FILE}
                """
            }
        }

        stage('Check Image Directory') {
            steps {
                echo 'Checking if the image exists...'
                sh 'pwd'
                sh 'ls -l /var/lib/jenkins/workspace/goldenimage/ || echo "Directory not found"'
            }
        }

        stage('Archive Image') {
            steps {
                script {
                    if (fileExists(env.LOCAL_IMAGE_PATH)) {
                        echo "Archiving image: ${env.LOCAL_IMAGE_PATH}"
                        archiveArtifacts artifacts: "${env.LOCAL_IMAGE_PATH}", fingerprint: true
                    } else {
                        error "Image file not found: ${env.LOCAL_IMAGE_PATH}"
                    }
                }
            }
        }

        stage('Upload Image to Another OpenStack Environment') {
            steps {
                script {
                    def uploadScript = "/var/lib/jenkins/workspace/goldenimage/upload_to_glance.sh"
                    def imageFile = env.LOCAL_IMAGE_PATH
                    def imageName = "${env.IMAGE_NAME}-${env.IMAGE_TIMESTAMP}"

                    sh """
                        if [ ! -f "${uploadScript}" ]; then
                            echo "ERROR: Upload script not found: ${uploadScript}"
                            exit 1
                        fi

                        chmod +x "${uploadScript}"

                        echo "Uploading image ${imageFile} as ${imageName}..."
                        ${uploadScript} "${imageFile}" "${imageName}"
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
