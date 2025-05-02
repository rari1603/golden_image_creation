pipeline {
    agent any

    environment {
        PACKER_FILE      = 'openstack.pkr.hcl'
        PACKER_VARS      = 'openstack.pkrvars.hcl'
        IMAGE_BASE_NAME  = 'patched-rhel9.2'
        IMAGE_TIMESTAMP  = "${new Date().format('yyyyMMddHHmmss')}"
        LOCAL_IMAGE_PATH = "/var/lib/jenkins/images/${IMAGE_BASE_NAME}.qcow2"
        VENV_DIR         = "/var/lib/jenkins/venv"
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', credentialsId: '03', url: 'https://github.com/rari1603/golden_image_creation.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh """
                    python3.9 -m venv ${VENV_DIR}
                    source ${VENV_DIR}/bin/activate
                    pip install --upgrade pip
                    pip install python-openstackclient
                """
            }
        }

        stage('Clean Existing Image') {
            steps {
                sh """
                    source ${VENV_DIR}/bin/activate
                    packer build -only=cleanup-existing-image.null.cleanup \
                        -var 'openstack_username=$OS_USERNAME' \
                        -var 'openstack_password=$OS_PASSWORD' \
                        -var 'openstack_tenant_name=$OS_PROJECT_NAME' \
                        -var 'openstack_auth_url=$OS_AUTH_URL' \
                        ${PACKER_FILE}
                """
            }
        }

        stage('Build New Image') {
            steps {
                sh """
                    source ${VENV_DIR}/bin/activate
                    packer build -only=rhel9.2-b2b-image.openstack.rhel_image \
                        -var 'openstack_username=$OS_USERNAME' \
                        -var 'openstack_password=$OS_PASSWORD' \
                        -var 'openstack_tenant_name=$OS_PROJECT_NAME' \
                        -var 'openstack_auth_url=$OS_AUTH_URL' \
                        ${PACKER_FILE}
                """
            }
        }

        stage('Verify Image Saved') {
            steps {
                sh """
                    echo "Checking saved image: ${LOCAL_IMAGE_PATH}"
                    ls -lh ${LOCAL_IMAGE_PATH} || echo 'Image not found!'
                """
            }
        }

        stage('Archive Image') {
            steps {
                archiveArtifacts artifacts: "${LOCAL_IMAGE_PATH}", fingerprint: true
            }
        }

        stage('Upload Image to Target OpenStack') {
            steps {
                script {
                    def imageName = "${IMAGE_BASE_NAME}-${IMAGE_TIMESTAMP}"
                    sh """
                        if [ ! -f /var/lib/jenkins/workspace/goldenimage/openstack.env ]; then
                            echo "ERROR: Destination OpenStack credentials not found!"
                            exit 1
                        fi

                        echo "Uploading image '${imageName}' to destination cloud..."

                        source ${VENV_DIR}/bin/activate
                        set -a
                        source /var/lib/jenkins/workspace/goldenimage/openstack.env
                        set +a

                        openstack token issue || { echo "Auth failed"; exit 1; }

                        openstack image create \\
                          --disk-format qcow2 \\
                          --container-format bare \\
                          --public \\
                          --file ${LOCAL_IMAGE_PATH} \\
                          "${imageName}"

                        echo "Upload successful."
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
            cleanWs()
        }
        failure {
            echo "Build failed!"
        }
    }
}
