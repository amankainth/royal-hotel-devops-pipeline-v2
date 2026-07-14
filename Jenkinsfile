pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TMPDIR             = '/var/tmp'
        JAVA_TOOL_OPTIONS  = '-Djava.io.tmpdir=/var/tmp'
        TF_IN_AUTOMATION   = 'true'
        TF_INPUT           = '0'
        TF_CLI_ARGS        = '-no-color'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '30'))
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '📥 Pulling code from GitHub...'
                checkout scm
            }
        }

        stage('Prepare Environment') {
            steps {
                sh '''
                    mkdir -p /var/lib/jenkins/.ssh
                    chmod 700 /var/lib/jenkins/.ssh
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    echo '⚙️  Initializing Terraform with S3 backend...'
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    echo '🔍 Validating Terraform configuration...'
                    sh 'terraform fmt -check -diff || echo "⚠️  Formatting issues (not blocking)"'
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            options { timeout(time: 5, unit: 'MINUTES') }
            steps {
                dir('terraform') {
                    echo '📋 Planning infrastructure changes...'
                    sh 'terraform plan -input=false -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            options { timeout(time: 10, unit: 'MINUTES') }
            steps {
                dir('terraform') {
                    echo '🚀 Provisioning infrastructure...'
                    sh 'terraform apply -input=false -auto-approve tfplan'
                }
            }
        }

        stage('Extract Outputs') {
            steps {
                dir('terraform') {
                    script {
                        env.DEV_INSTANCE_IP = sh(
                            script: 'terraform output -raw dev_instance_public_ip',
                            returnStdout: true
                        ).trim()

                        env.SSH_KEY_PATH = sh(
                            script: 'terraform output -raw ssh_key_path',
                            returnStdout: true
                        ).trim()

                        echo "✅ Dev Server IP: ${env.DEV_INSTANCE_IP}"
                        echo "🔑 SSH Key: ${env.SSH_KEY_PATH}"
                    }
                }
            }
        }

        stage('Configure Ansible Inventory') {
            steps {
                sh """
                    cat > ansible/inventory.ini <<EOL
[webservers]
${env.DEV_INSTANCE_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${env.SSH_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
EOL
                    echo "=== Inventory ==="
                    cat ansible/inventory.ini
                """
            }
        }

        stage('Wait for SSH Ready') {
            steps {
                echo '⏳ Waiting 45s for server SSH...'
                sleep(time: 45, unit: 'SECONDS')

                sh """
                    for i in {1..10}; do
                        if ssh -i ${env.SSH_KEY_PATH} -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@${env.DEV_INSTANCE_IP} 'echo ready' 2>/dev/null; then
                            echo "✅ SSH is ready"
                            exit 0
                        fi
                        echo "SSH not ready, waiting 10s..."
                        sleep 10
                    done
                    echo "❌ SSH did not become ready in time"
                    exit 1
                """
            }
        }

        stage('Ansible Configuration') {
            options { timeout(time: 20, unit: 'MINUTES') }
            steps {
                dir('ansible') {
                    echo '🔧 Running Ansible playbook...'
                    sh 'ansible-playbook -i inventory.ini playbook.yml -v'
                }
            }
        }

        stage('Deployment Summary') {
            steps {
                echo """
                ✅ DEPLOYMENT SUCCESSFUL

                Dev Server IP:  ${env.DEV_INSTANCE_IP}
                App URL:        http://${env.DEV_INSTANCE_IP}
                SSH Command:    ssh -i ${env.SSH_KEY_PATH} ec2-user@${env.DEV_INSTANCE_IP}
                """
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed - check logs above'
        }
        aborted {
            echo '⚠️  Pipeline aborted'
        }
        cleanup {
            sh 'rm -f terraform/tfplan 2>/dev/null || true'
            cleanWs deleteDirs: true, notFailBuild: true, patterns: [
                [pattern: '**/tfplan', type: 'INCLUDE'],
                [pattern: '**/*.tfstate*', type: 'EXCLUDE']
            ]
        }
    }
}
