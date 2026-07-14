pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'

        // Avoid tmpfs /tmp issue on Amazon Linux 2023
        TMPDIR             = '/var/tmp'
        JAVA_TOOL_OPTIONS  = '-Djava.io.tmpdir=/var/tmp'

        // Terraform automation settings
        TF_IN_AUTOMATION   = 'true'
        TF_INPUT           = '0'
        TF_CLI_ARGS        = '-no-color'
    }

    options {
        timeout(time: 40, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '30'))
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo 'Pulling code from GitHub...'
                checkout scm
            }
        }

        stage('Prepare Jenkins Environment') {
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
                    echo 'Initializing Terraform with S3 backend...'
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    echo 'Validating Terraform configuration...'

                    sh '''
                        terraform fmt -check -diff || echo "Terraform formatting issues found, but not blocking pipeline."
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            options {
                timeout(time: 5, unit: 'MINUTES')
            }

            steps {
                dir('terraform') {
                    echo 'Creating Terraform execution plan...'
                    sh 'terraform plan -input=false -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            options {
                timeout(time: 15, unit: 'MINUTES')
            }

            steps {
                dir('terraform') {
                    echo 'Provisioning AWS infrastructure...'
                    sh 'terraform apply -input=false -auto-approve tfplan'
                }
            }
        }

        stage('Extract Terraform Outputs') {
            steps {
                dir('terraform') {
                    script {
                        echo 'Extracting Terraform outputs...'

                        env.DEV_INSTANCE_IP = sh(
                            script: 'terraform output -raw dev_instance_public_ip',
                            returnStdout: true
                        ).trim()

                        env.SSH_KEY_PATH = sh(
                            script: 'terraform output -raw ssh_key_path',
                            returnStdout: true
                        ).trim()

                        echo "Dev Server IP: ${env.DEV_INSTANCE_IP}"
                        echo "SSH Key Path: ${env.SSH_KEY_PATH}"
                    }
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                echo 'Generating Ansible inventory dynamically from Terraform output...'

                sh """
                    cat > ansible/inventory.ini <<EOL
[webservers]
${env.DEV_INSTANCE_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${env.SSH_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
EOL

                    echo "Generated Ansible inventory:"
                    cat ansible/inventory.ini
                """
            }
        }

        stage('Wait for EC2 SSH') {
            options {
                timeout(time: 5, unit: 'MINUTES')
            }

            steps {
                echo 'Waiting for EC2 SSH to become available...'

                sh """
                    for i in {1..18}; do
                        if ssh -i ${env.SSH_KEY_PATH} \\
                            -o StrictHostKeyChecking=no \\
                            -o UserKnownHostsFile=/dev/null \\
                            -o ConnectTimeout=5 \\
                            ec2-user@${env.DEV_INSTANCE_IP} 'echo SSH_READY' 2>/dev/null; then

                            echo "SSH is ready."
                            exit 0
                        fi

                        echo "SSH not ready yet. Retrying in 10 seconds..."
                        sleep 10
                    done

                    echo "SSH did not become ready in time."
                    exit 1
                """
            }
        }

        stage('Run Ansible Playbook') {
            options {
                timeout(time: 25, unit: 'MINUTES')
            }

            steps {
                dir('ansible') {
                    echo 'Running Ansible playbook to deploy Royal Hotel application...'
                    sh 'ansible-playbook -i inventory.ini playbook.yml -v'
                }
            }
        }

        stage('Verify Application from Jenkins') {
            steps {
                echo 'Verifying application from Jenkins server...'

                sh """
                    echo "Checking application URL: http://${env.DEV_INSTANCE_IP}:8080"

                    for i in {1..12}; do
                        HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://${env.DEV_INSTANCE_IP}:8080 || true)

                        echo "Attempt \$i: HTTP status code = \$HTTP_CODE"

                        if [ "\$HTTP_CODE" = "200" ] || [ "\$HTTP_CODE" = "302" ] || [ "\$HTTP_CODE" = "401" ] || [ "\$HTTP_CODE" = "403" ]; then
                            echo "Application is responding."
                            exit 0
                        fi

                        echo "Application not ready yet. Retrying in 10 seconds..."
                        sleep 10
                    done

                    echo "Application did not respond successfully."
                    exit 1
                """
            }
        }

        stage('Deployment Summary') {
            steps {
                echo """
==================================================
DEPLOYMENT SUCCESSFUL
==================================================

Dev Server IP:
${env.DEV_INSTANCE_IP}

Application URL:
http://${env.DEV_INSTANCE_IP}:8080

SSH Command:
ssh -i ${env.SSH_KEY_PATH} ec2-user@${env.DEV_INSTANCE_IP}

Systemd Service on Dev Server:
royal-hotel

Useful Commands:
sudo systemctl status royal-hotel --no-pager
sudo journalctl -u royal-hotel -n 100 --no-pager
curl -I http://localhost:8080

==================================================
"""
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded. Royal Hotel application deployed successfully.'
        }

        failure {
            echo 'Pipeline failed. Please check the stage logs above.'
        }

        aborted {
            echo 'Pipeline aborted.'
        }

        cleanup {
            echo 'Cleaning Jenkins workspace...'

            sh '''
                rm -f terraform/tfplan 2>/dev/null || true
                rm -f ansible/inventory.ini 2>/dev/null || true
            '''

            cleanWs(
                deleteDirs: true,
                notFailBuild: true,
                patterns: [
                    [pattern: '**/tfplan', type: 'INCLUDE'],
                    [pattern: '**/.terraform/**', type: 'INCLUDE'],
                    [pattern: '**/*.tfstate*', type: 'EXCLUDE']
                ]
            )
        }
    }
}
