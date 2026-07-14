<div align="center">

<h1>🏨 Royal Hotel DevOps Pipeline</h1>

<p>
End-to-End Infrastructure Provisioning and CI/CD Automation using
AWS, Terraform, Jenkins and Ansible
</p>

<p>
/Terraform-IaC-623CE4?logo=terraform&logoColor=white">
adge/AWS-Cloud-FF9900?logo=amazonaws&logoColor=white">
<img src="https://imgins&logoColor=white">
sible-Automation-EE0000?logo=ansible&logoColor=white">
/GitHub-Repository-181717?logo=github&logoColor=white">
</p>

</div>

<hr>

<h2>📖 Project Overview</h2>

<p>
Royal Hotel DevOps Pipeline demonstrates a complete Infrastructure as Code (IaC)
and CI/CD implementation on AWS.
</p>

<p>
The solution automates infrastructure provisioning using Terraform,
configuration management using Ansible,
and deployment orchestration through Jenkins.
</p>

<ul>
<li>✅ Infrastructure as Code with Terraform</li>
<li>✅ Jenkins CI/CD Automation</li>
<li>✅ Ansible Configuration Management</li>
<li>✅ Amazon S3 Remote State Backend</li>
<li>✅ DynamoDB State Locking</li>
<li>✅ AWS EC2 Automated Provisioning</li>
<li>✅ Automated Infrastructure Destruction</li>
<li>✅ IAM Role Based Authentication</li>
</ul>

<hr>

<h2>🏗️ Solution Architecture</h2>

<pre>
+--------------------+
|      GitHub        |
| Source Repository  |
+---------+----------+
          |
          |
          ▼
+--------------------+
|      Jenkins       |
|   CI/CD Pipeline   |
+---------+----------+
          |
          ▼
+--------------------+
|    Terraform       |
| Infrastructure     |
| Provisioning       |
+---------+----------+
          |
          ▼
+--------------------+
|       AWS          |
| EC2 / VPC / SG     |
+---------+----------+
          |
          ▼
+--------------------+
|      Ansible       |
| Configuration      |
+---------+----------+
          |
          ▼
+--------------------+
| Application Server |
+--------------------+
</pre>

<hr>

<h2>🚀 Features</h2>

<h3>Infrastructure Provisioning</h3>

<ul>
<li>Amazon VPC</li>
<li>Public Subnet</li>
<li>Internet Gateway</li>
<li>Route Tables</li>
<li>Security Groups</li>
<li>EC2 Instances</li>
<li>SSH Key Management</li>
</ul>

<h3>Terraform Backend</h3>

<ul>
<li>Amazon S3 State Storage</li>
<li>DynamoDB State Locking</li>
<li>Versioned State Files</li>
<li>Encrypted Backend Storage</li>
</ul>

<h3>CI/CD Pipeline</h3>

<ul>
<li>GitHub Integration</li>
<li>Terraform Validate</li>
<li>Terraform Plan</li>
<li>Terraform Apply</li>
<li>Terraform Destroy</li>
<li>Automated Cleanup</li>
</ul>

<h3>Configuration Management</h3>

<ul>
<li>Docker Installation</li>
<li>Git Installation</li>
<li>Java Installation</li>
<li>Node.js Installation</li>
<li>Application Deployment</li>
</ul>

<hr>

<h2>📂 Repository Structure</h2>

<pre>
royal-hotel-devops-pipeline-v2
│
├── Jenkinsfile
├── Jenkinsfile.destroy
├── README.md
│
├── terraform
│   ├── backend.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
│
├── ansible
│   ├── ansible.cfg
│   ├── inventory.ini.example
│   └── playbook.yml
│
└── bootstrap
    └── setup-backend.sh
</pre>

<hr>

<h2>⚙️ Technology Stack</h2>

<table>
<tr>
<th>Category</th>
<th>Technology</th>
</tr>

<tr>
<td>Cloud Platform</td>
<td>AWS</td>
</tr>

<tr>
<td>Infrastructure as Code</td>
<td>Terraform</td>
</tr>

<tr>
<td>CI/CD</td>
<td>Jenkins</td>
</tr>

<tr>
<td>Configuration Management</td>
<td>Ansible</td>
</tr>

<tr>
<td>Backend State</td>
<td>Amazon S3</td>
</tr>

<tr>
<td>State Locking</td>
<td>DynamoDB</td>
</tr>

<tr>
<td>Version Control</td>
<td>GitHub</td>
</tr>
</table>

<hr>

<h2>🔄 Deployment Workflow</h2>

<ol>
<li>Developer pushes code to GitHub</li>
<li>Jenkins pipeline starts</li>
<li>Terraform validates infrastructure</li>
<li>Terraform creates execution plan</li>
<li>Terraform provisions AWS resources</li>
<li>Ansible configures the server</li>
<li>Application deployment completes</li>
</ol>

<hr>

<h2>💥 Destroy Workflow</h2>

<p>
A dedicated Jenkins destroy pipeline safely removes all infrastructure:
</p>

<pre>
terraform destroy -auto-approve
</pre>

<p>
Destroy operations require explicit approval before execution.
</p>

<hr>

<h2>🔐 Security Highlights</h2>

<ul>
<li>IAM Role Authentication</li>
<li>No Hardcoded AWS Credentials</li>
<li>Encrypted Terraform Backend</li>
<li>State Lock Protection</li>
<li>Security Group Controls</li>
<li>Remote State Management</li>
</ul>

<hr>

<h2>📊 AWS Resources Created</h2>

<ul>
<li>VPC</li>
<li>Public Subnet</li>
<li>Internet Gateway</li>
<li>Route Tables</li>
<li>Security Groups</li>
<li>EC2 Instance</li>
<li>Amazon S3 Bucket</li>
<li>DynamoDB Table</li>
</ul>

<hr>

<h2>📷 Screenshots</h2>

<p>Screenshots after deployment.</p>

<pre>
screenshots/
├── jenkins-success.png
├── terraform-apply.png
├── aws-ec2-instance.png
├── aws-s3-backend.png
└── application-homepage.png
</pre>

<hr>

<h2>🌟 Future Enhancements</h2>

<ul>
<li>GitHub Webhooks</li>
<li>HTTPS using Let's Encrypt</li>
<li>AWS Load Balancer</li>
<li>Route53 Integration</li>
<li>Auto Scaling Groups</li>
<li>ECS / Kubernetes Deployment</li>
<li>CloudWatch Monitoring</li>
<li>Slack Notifications</li>
</ul>

<hr>

<h2>🎯 Key Learning Areas</h2>

<ul>
<li>Infrastructure as Code</li>
<li>Terraform State Management</li>
<li>AWS Networking</li>
<li>CI/CD Design</li>
<li>Configuration Management</li>
<li>Cloud Automation</li>
<li>DevOps Best Practices</li>
</ul>

<hr>

<h2>👨‍💻 Author</h2>

<p>
<b>Amandeep Kainth</b>
Pune, India
</p>

<hr>

<div align="center">

<h2>⭐ If you found this project useful, please consider giving it a Star!</h2>

<p>
Built with ❤️ using Terraform, Jenkins, Ansible and AWS
</p>

</div>
