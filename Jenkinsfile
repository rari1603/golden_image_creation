pipeline {
    agent any

    environment {
        PACKER_VARS = 'openstack.pkrvars.hcl'
        PACKER_FILE = 'openstack.pkr.hcl'
        IMAGE_NAME  = 'patched-rhel9.2'
        IMAGE_FILE_PATH = '/var/lib/jenkins/images/patched-rhel9.2.qcow2'
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

        stage('Check Image File') {
            steps {
                script {
                    if (!fileExists(env.IMAGE_FILE_PATH)) {
                        error "Image file not found at ${env.IMAGE_FILE_PATH}"
                    }
                    sh "ls -lh ${env.IMAGE_FILE_PATH}"
                }
            }
        }

        stage('Archive Image') {
    steps {
        script {
            def copiedPath = "${WORKSPACE}/patched-rhel9.2.qcow2"
            sh "cp ${env.IMAGE_FILE_PATH} ${copiedPath}"
            archiveArtifacts artifacts: 'patched-rhel9.2.qcow2', fingerprint: true
        }
    }
}

        stage('Upload Image to Another OpenStack Environment') {
            steps {
                script {
                    def uploadScript = "${WORKSPACE}/golden_image_creation/upload_to_glance.sh"
                    def glanceImageName = "${env.IMAGE_NAME}-${env.IMAGE_TIMESTAMP}"

                    sh """
                        if [ ! -f "${uploadScript}" ]; then
                            echo "Upload script not found: ${uploadScript}"
                            exit 1
                        fi

                        chmod +x "${uploadScript}"
                        ${uploadScript} "${env.IMAGE_FILE_PATH}" "${glanceImageName}"
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
