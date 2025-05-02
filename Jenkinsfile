pipeline {
    agent any

    parameters {
        string(name: 'openstack_username', defaultValue: '', description: 'OpenStack Username')
        string(name: 'openstack_password', defaultValue: '', description: 'OpenStack Password')
        string(name: 'openstack_tenant_name', defaultValue: '', description: 'OpenStack Tenant Name')
        string(name: 'openstack_auth_url', defaultValue: '', description: 'OpenStack Auth URL')
        string(name: 'openstack_domain_name', defaultValue: '', description: 'OpenStack Domain Name')
    }

    environment {
        PACKER_LOG = '1'
    }

    stages {
        stage('Set Variables') {
            steps {
                script {
                    // Assign domain name with fallback to "Default"
                    env.OS_DOMAIN_NAME = params.openstack_domain_name?.trim() ?:
                                         'Default'

                    // Generate image name once and reuse
                    env.IMAGE_NAME = "patched-rhel9.2-${new Date().format('yyyyMMddHHmmss')}"
                }
            }
        }

        stage('Cleanup Existing Image') {
            steps {
                script {
                    echo "Cleaning up image: ${env.IMAGE_NAME}"
                    sh """
                        export OS_AUTH_URL="${params.openstack_auth_url}"
                        export OS_USERNAME="${params.openstack_username}"
                        export OS_PASSWORD="${params.openstack_password}"
                        export OS_PROJECT_NAME="${params.openstack_tenant_name}"
                        export OS_USER_DOMAIN_NAME="${env.OS_DOMAIN_NAME}"
                        export OS_PROJECT_DOMAIN_NAME="${env.OS_DOMAIN_NAME}"
                        export OS_COMPUTE_API_VERSION=2.1
                        export OS_IMAGE_API_VERSION=2
                        export OS_INSECURE=true

                        EXISTING_IMAGE=\$(openstack image list --name ${env.IMAGE_NAME} -f value -c ID)
                        if [ -n "\$EXISTING_IMAGE" ]; then
                            echo "Deleting existing image \$EXISTING_IMAGE..."
                            openstack image delete "\$EXISTING_IMAGE" || echo 'Warning: Could not delete image.'
                        else
                            echo "No existing image found."
                        fi
                    """
                }
            }
        }

        stage('Build Image with Packer') {
            steps {
                script {
                    echo "Running packer build with image name: ${env.IMAGE_NAME}"
                    sh """
                        packer build \
                          -var "openstack_username=${params.openstack_username}" \
                          -var "openstack_password=${params.openstack_password}" \
                          -var "openstack_tenant_name=${params.openstack_tenant_name}" \
                          -var "openstack_auth_url=${params.openstack_auth_url}" \
                          -var "openstack_domain_name=${env.OS_DOMAIN_NAME}" \
                          -var "image_name=${env.IMAGE_NAME}" \
                          openstack.packer.hcl
                    """
                }
            }
        }

        stage('Save Image Locally') {
            steps {
                script {
                    echo "Saving image ${env.IMAGE_NAME} locally..."
                    sh """
                        export OS_AUTH_URL="${params.openstack_auth_url}"
                        export OS_USERNAME="${params.openstack_username}"
                        export OS_PASSWORD="${params.openstack_password}"
                        export OS_PROJECT_NAME="${params.openstack_tenant_name}"
                        export OS_USER_DOMAIN_NAME="${env.OS_DOMAIN_NAME}"
                        export OS_PROJECT_DOMAIN_NAME="${env.OS_DOMAIN_NAME}"
                        export OS_COMPUTE_API_VERSION=2.1
                        export OS_IMAGE_API_VERSION=2
                        export OS_INSECURE=true

                        openstack image save ${env.IMAGE_NAME} --file ${env.IMAGE_NAME}.qcow2 || echo 'Warning: Save failed.'
                    """
                }
            }
        }

        stage('Archive Image') {
            steps {
                script {
                    echo "Archiving ${env.IMAGE_NAME}.qcow2..."
                    archiveArtifacts artifacts: "${env.IMAGE_NAME}.qcow2", onlyIfSuccessful: true
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning workspace..."
            cleanWs()
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
