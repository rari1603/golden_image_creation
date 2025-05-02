pipeline {
  agent any

  environment {
    IMAGE_DIR = "/var/lib/jenkins/images"
  }

  stages {
    stage('Checkout Code') {
      steps {
        git url: 'https://github.com/rari1603/golden_image_creation.git'
      }
    }

    stage('Run Packer Build') {
      steps {
        sh '''
          echo "Running Packer build..."
          packer init openstack.pkr.hcl
          packer build -var "openstack_username=${OS_USERNAME}" \
                       -var "openstack_password=${OS_PASSWORD}" \
                       -var "openstack_auth_url=${OS_AUTH_URL}" \
                       -var "openstack_tenant_name=${OS_PROJECT_NAME}" \
                       -var "openstack_domain_name=Default" \
                       openstack.pkr.hcl
        '''
      }
    }

    stage('Check Image File') {
      steps {
        sh '''
          echo "Checking image directory..."
          ls -lh ${IMAGE_DIR} || echo "Image directory not found"
        '''
      }
    }

    stage('Archive Image') {
      steps {
        archiveArtifacts artifacts: 'images/*.qcow2', allowEmptyArchive: true
      }
    }

    stage('Upload to Another OpenStack Env') {
      steps {
        sh '''
          echo "Uploading to second OpenStack environment..."
          # You can override env vars or source another RC file here
          # openstack image create --file /var/lib/jenkins/images/patched-rhel9.2.qcow2 --disk-format qcow2 --container-format bare NEW_IMAGE_NAME
        '''
      }
    }
  }

  post {
    always {
      echo 'Build process completed.'
      cleanWs()
    }
    failure {
      echo 'Build failed!'
    }
  }
}
