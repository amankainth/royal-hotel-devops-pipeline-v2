===============================================================
SSH KEY FLOW: TERRAFORM CONTROL NODE TO DEV SERVER FOR ANSIBLE
===============================================================

Author: Amandeep Kainth
Project: Royal Hotel DevOps Pipeline v2
Date: July 2026

================================================================
THE BIG PICTURE
================================================================

Terraform Control Node (Jenkins)
        |
        | Uses tls_private_key provider
        v
Generates RSA 4096-bit keypair in memory
        |
        +--- Public Key -------+
        |                      |
        |                      v
        |          AWS EC2 Keypair Registry
        |          (aws_key_pair.dev_key)
        |                      |
        |                      | Attached to EC2 at boot
        |                      v
        |                Dev Server EC2
        |                ~/.ssh/authorized_keys
        |
        +--- Private Key -------+
                                |
                                v
              /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem
              (on Jenkins control node)
                                |
                                | Used by Ansible for SSH
                                v
                        SSH to Dev Server

KEY INSIGHT: The private key stays on Jenkins. The public key
gets pushed to AWS, which then places it on the dev server's
authorized_keys. Ansible uses the private key to SSH.


================================================================
STEP 1: TERRAFORM GENERATES THE KEYPAIR
================================================================

File: terraform/main.tf

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

What happens:
Terraform's tls provider generates an RSA 4096-bit keypair
in memory during terraform apply.

This creates two values:
- tls_private_key.dev_key.private_key_pem     (private key, PEM format)
- tls_private_key.dev_key.public_key_openssh  (public key, OpenSSH format)


================================================================
STEP 2: PUBLIC KEY REGISTERED WITH AWS
================================================================

File: terraform/main.tf

resource "aws_key_pair" "dev_key" {
  key_name   = "royal-hotel-dev-key"
  public_key = tls_private_key.dev_key.public_key_openssh
}

What happens:
Terraform uploads the public key to AWS as a named keypair
called "royal-hotel-dev-key".

Verify in AWS Console:
EC2 -> Key Pairs -> royal-hotel-dev-key

Or CLI:
aws ec2 describe-key-pairs --key-names royal-hotel-dev-key


================================================================
STEP 3: PRIVATE KEY SAVED ON JENKINS
================================================================

File: terraform/main.tf

resource "local_sensitive_file" "dev_key_pem" {
  content         = tls_private_key.dev_key.private_key_pem
  filename        = var.ssh_key_path
  file_permission = "0400"
}

File: terraform/variables.tf

variable "ssh_key_path" {
  default = "/var/lib/jenkins/.ssh/royal-hotel-dev-key.pem"
}

What happens:
The private key gets written to the Jenkins server at:
/var/lib/jenkins/.ssh/royal-hotel-dev-key.pem

With permission 0400 (owner read-only).

Verify:
sudo ls -la /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem

Expected output:
-r-------- 1 jenkins jenkins 3243 Jul 14 11:29 /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem


================================================================
STEP 4: EC2 INSTANCE ATTACHES THE AWS KEYPAIR
================================================================

File: terraform/main.tf

resource "aws_instance" "dev_instance" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.dev_instance.id]
  key_name               = aws_key_pair.dev_key.key_name
}

What happens:
When AWS launches the dev EC2 instance, it sees:
key_name = "royal-hotel-dev-key"

AWS automatically:
1. Reads the public key from AWS keypair registry
2. Writes it to /home/ec2-user/.ssh/authorized_keys
3. Sets proper permissions

This is done by cloud-init at boot time.

Verify on the dev server:
ssh -i /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem ec2-user@54.211.144.46
cat ~/.ssh/authorized_keys


================================================================
STEP 5: JENKINSFILE EXTRACTS THE KEY PATH
================================================================

File: Jenkinsfile

stage('Extract Terraform Outputs') {
    steps {
        dir('terraform') {
            script {
                env.SSH_KEY_PATH = sh(
                    script: 'terraform output -raw ssh_key_path',
                    returnStdout: true
                ).trim()
            }
        }
    }
}

File: terraform/outputs.tf

output "ssh_key_path" {
  value       = local_sensitive_file.dev_key_pem.filename
  description = "Path to SSH private key on Jenkins"
}

What happens:
Jenkinsfile queries Terraform for the SSH key location.
Terraform returns: /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem

Now Jenkins has the path in env.SSH_KEY_PATH.


================================================================
STEP 6: JENKINSFILE GENERATES ANSIBLE INVENTORY
================================================================

File: Jenkinsfile

stage('Generate Ansible Inventory') {
    steps {
        sh """
            cat > ansible/inventory.ini <<EOL
[webservers]
${env.DEV_INSTANCE_IP} ansible_user=ec2-user ansible_ssh_private_key_file=${env.SSH_KEY_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
EOL
        """
    }
}

What happens:
Jenkinsfile writes an inventory file that tells Ansible:
- Which server to connect to: 54.211.144.46
- Which user to SSH as: ec2-user
- Which private key to use: /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem
- SSH options: skip host key check


================================================================
STEP 7: ANSIBLE USES THE KEY FOR SSH
================================================================

File: Jenkinsfile

stage('Run Ansible Playbook') {
    steps {
        dir('ansible') {
            sh 'ansible-playbook -i inventory.ini playbook.yml -v'
        }
    }
}

What happens:
Ansible reads the inventory, then for each task:
1. Reads private key from /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem
2. Establishes SSH connection: ssh -i <key> ec2-user@54.211.144.46
3. AWS EC2 checks: Does this private key match a public key
   in authorized_keys?
4. Match found: connection allowed
5. Ansible sends commands over the SSH tunnel


================================================================
COMPLETE FLOW VISUALIZATION
================================================================

+----------------------------------------------------------------+
|  Jenkins Control Node                                          |
|                                                                |
|  Terraform Apply                                               |
|    |                                                           |
|    +--> tls_private_key.dev_key                                |
|    |       - Generates RSA 4096 keypair (in memory)            |
|    |                                                           |
|    +--> aws_key_pair.dev_key                                   |
|    |       - Uploads public key to AWS                         |
|    |                                                           |
|    +--> local_sensitive_file.dev_key_pem                       |
|    |       - Writes private key to filesystem                  |
|    |       - Path: /var/lib/jenkins/.ssh/royal-hotel-dev-key   |
|    |                                                           |
|    +--> aws_instance.dev_instance                              |
|            - key_name = royal-hotel-dev-key                    |
|            - AWS injects public key into instance              |
+----------------------------------------------------------------+
                        |
                        | SSH via Ansible
                        v
+----------------------------------------------------------------+
|  Dev Server EC2 (54.211.144.46)                                |
|                                                                |
|  /home/ec2-user/.ssh/authorized_keys                           |
|    - Contains public key from AWS keypair                      |
|    - Placed here by cloud-init at boot                         |
|                                                                |
|  When Ansible connects:                                        |
|    - Presents private key                                      |
|    - Server verifies against authorized_keys                   |
|    - Access granted                                            |
+----------------------------------------------------------------+


================================================================
VERIFICATION COMMANDS
================================================================

Check 1: Private key exists on Jenkins
--------------------------------------
sudo ls -la /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem

Expected:
-r-------- 1 jenkins jenkins 3243 Jul 14 11:29 /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem


Check 2: Public key registered in AWS
--------------------------------------
aws ec2 describe-key-pairs --key-names royal-hotel-dev-key --region us-east-1

Expected: JSON showing KeyName, KeyFingerprint, KeyPairId


Check 3: Public key on dev server
--------------------------------------
ssh -i /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem ec2-user@54.211.144.46 "cat ~/.ssh/authorized_keys"

Expected: A long line starting with "ssh-rsa AAAAB3NzaC1yc2EAAAAD..."


Check 4: Ansible can SSH
--------------------------------------
sudo -u jenkins ansible -i inventory.ini webservers -m ping

Expected:
54.211.144.46 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}


================================================================
SECURITY NOTES
================================================================

Private Key Sensitivity:
- Location: /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem
- Permission 0400 limits access to jenkins user
- Root can also read it (root reads anything)
- Stored in plaintext on Jenkins disk

Storage in Terraform State:
- Private key ALSO stored in terraform.tfstate on S3
- Stored in PLAINTEXT
- Anyone with S3 access can extract the key

Best Practices for Production:
- Use AWS Systems Manager Parameter Store
- Enable S3 bucket policy restrictions
- Encrypt state with AWS KMS
- Use HashiCorp Vault for secrets

For POC/dev: current setup is acceptable

What Happens on terraform destroy:
1. aws_instance.dev_instance deleted
2. aws_key_pair.dev_key deleted (AWS forgets public key)
3. local_sensitive_file.dev_key_pem deleted (Jenkins file removed)
4. tls_private_key.dev_key deleted (Terraform memory cleared)

Then terraform apply regenerates a COMPLETELY NEW keypair.
Old key becomes useless.


================================================================
WHY THIS DESIGN IS GREAT
================================================================

Pros:
- Fully automated - no manual key generation
- Zero human handling of private keys
- Ephemeral - fresh key on every destroy/apply
- No secrets in Git - keys generated at runtime
- Auditable - everything tracked in Terraform state

Cons:
- New key on every destroy - can't SSH with old key
- Requires Jenkins EC2 access - key only on Jenkins
- State contains sensitive data - protect S3 access
- No key rotation without destroy - need terraform taint


================================================================
QUICK REFERENCE - WHERE EVERYTHING LIVES
================================================================

Item                          | Location
------------------------------|--------------------------------
Key generation code           | terraform/main.tf (tls_private_key)
AWS key registration code     | terraform/main.tf (aws_key_pair)
Local file save code          | terraform/main.tf (local_sensitive_file)
Private key file              | /var/lib/jenkins/.ssh/royal-hotel-dev-key.pem
Public key in AWS             | AWS Console > EC2 > Key Pairs
Public key on dev server      | /home/ec2-user/.ssh/authorized_keys
Ansible inventory             | ansible/inventory.ini (auto-generated)
SSH connection                | Ansible calls SSH internally


================================================================
SIMPLE ANALOGY
================================================================

Think of it like a hotel:

1. Terraform                        = Hotel management software
2. Private key on Jenkins           = Master key card
3. Public key on AWS                = List of authorized guests
4. Public key on EC2 authorized_keys= Room door lock
5. Ansible                          = Housekeeping staff using master key
6. ec2-user                         = The room number

Everything coordinated automatically. Never touch a physical key.


================================================================
TL;DR SUMMARY
================================================================

QUESTION:
How does the key get from Terraform to the dev server for Ansible?

ANSWER:

1. Terraform generates RSA keypair (in memory)
2. Terraform uploads PUBLIC key to AWS as a Key Pair
3. Terraform saves PRIVATE key to Jenkins filesystem
4. Terraform launches EC2 with key_name reference
5. AWS injects public key into EC2 authorized_keys at boot
6. Ansible reads inventory, uses private key path, SSHes into EC2
7. Standard SSH key authentication grants access

All automatic. Zero manual steps. Fresh keys every deployment cycle.

This pattern is called:
"Ephemeral SSH keys managed by Terraform"

Common DevOps practice for infrastructure automation.


================================================================
END OF DOCUMENT
================================================================
