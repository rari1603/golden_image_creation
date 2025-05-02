pipeline {
    agent any
    parameters {
        string(name: 'openstack_username', defaultValue: '', description: 'OpenStack Username')
        string(name: 'openstack_password', defaultValue: '', description: 'OpenStack Password')
        string(name: 'openstack_tenant_name', defaultValue: '', description: 'OpenStack Tenant Name')
        string(name: 'openstack_auth_url', defaultValue: '', description: 'OpenStack Auth URL')
        string(name: 'openstack_domain_name', defaultValue: 'Default', description: 'OpenStack Domain Name')  // Default value here
    }
    
    environment {
        // Set default value for openstack_domain_name using Groovy's "elvis" operator
        openstack_domain_name = params.openstack_domain_name ?: 'Default'
    }

    stages {
        stage('Cleanup Existing Image') {
            steps {
                script {
                    // Dynamically generate image name using timestamp
                    def timestamp = new Date().format("yyyyMMddHHmmss")
                    def image_name = "patched-rhel9.2-${timestamp}"
                    
                    echo "Setting up OpenStack environment..."
                    sh """
                        export OS_AUTH_URL="${params.openstack_auth_url}"
                        export OS_USERNAME="${params.openstack_username}"
                        export OS_PASSWORD="${params.openstack_password}"
                        export OS_PROJECT_NAME="${params.openstack_tenant_name}"
                        export OS_USER_DOMAIN_NAME="${openstack_domain_name}"
                        export OS_PROJECT_DOMAIN_NAME="${openstack_domain_name}"
                        export OS_COMPUTE_API_VERSION=2.1
                        export OS_IMAGE_API_VERSION=2
                        export OS_INSECURE=true
                        echo "Checking if image ${image_name} already exists..."
                        EXISTING_IMAGE=\$(openstack image list --name ${image_name} -f value -c ID)
                        if [ -n "\$EXISTING_IMAGE" ]; then
                            echo "Image found: \$EXISTING_IMAGE. Attempting to delete it..."
                            openstack image delete "\$EXISTING_IMAGE" || echo 'Warning: Failed to delete image. Continuing...'
                        else
                            echo 'No existing image found.'
                        fi
                    """
                }
            }
        }

        stage('Build Image with Packer - RHEL Image') {
            steps {
                script {
                    // Dynamically generate image name using timestamp
                    def timestamp = new Date().format("yyyyMMddHHmmss")
                    def image_name = "patched-rhel9.2-${timestamp}"

                    echo "Building the RHEL image with Packer..."
                    sh """
                        packer build -only=cleanup-existing-image.null.cleanup -var image_name=${image_name} -var openstack_username=${params.openstack_username} -var openstack_password=${params.openstack_password} -var openstack_tenant_name=${params.openstack_tenant_name} -var openstack_auth_url=${params.openstack_auth_url} openstack.pkr.hcl
                    """
                }
            }
        }

        stage('Save Image Locally') {
            steps {
                script {
                    echo "Saving image locally..."
                    def timestamp = new Date().format("yyyyMMddHHmmss")
                    def image_name = "patched-rhel9.2-${timestamp}"
                    sh """
                        openstack image save ${image_name} --file ${image_name}.qcow2 || echo 'Warning: Image save failed.'
                    """
                }
            }
        }

        stage('Archive Image') {
            steps {
                script {
                    echo "Archiving image..."
                    def timestamp = new Date().format("yyyyMMddHHmmss")
                    def image_name = "patched-rhel9.2-${timestamp}"
                    // Add your image archiving logic here
                }
            }
        }
    }

    post {
        always {
            echo "Build completed."
            cleanWs()
        }
        failure {
            echo "Build failed!"
        }
    }
}
