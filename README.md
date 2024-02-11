# Torch AWS Terraform Configuration

This Terraform configuration sets up an API server on AWS using EC2 instances, RDS database, VPC, subnet, internet gateway, and security groups. The API server is configured to allow SSH connections only from a specified IP address and HTTPS traffic from anywhere.

### Prerequisites

Before using this Terraform configuration, make sure you have the following prerequisites:

<ol>
<li>
<strong>AWS Account:</strong> You need an AWS account with appropriate permissions to create resources such as EC2 instances, RDS databases, VPCs, subnets, etc.
</li>
<li>
<strong>Terraform Installed:</strong> Make sure you have Terraform installed on your local machine. You can download it from the official Terraform website and follow the installation instructions.
</li>
<li>
<strong>SSH Key Pair:</strong> Generate an SSH key pair that will be used to connect to the EC2 instances. You can generate an SSH key pair using ssh-keygen:

    ssh-keygen -t rsa -b 2048 -f torch-server-keypair

</li>
<li>
<strong>Add <code>secret.tfvars</code> file:</strong> <code>secret.tfvars</code> file stores sensitive data related to Terraform configuration. An example file should look like this:

    db_username = "root" // Database username
    db_password = "123o3p72V9876AP8U00" // Database password
    personal_ip = "72.51.2.111/32" // Your own personal IP address. This is used so that you could ssh to EC2/RDS through your own machine
    ssl_certificate_arn = "arn:aws:acm:eu-north-1:073346272233:certificate/542bf11b-aac2-999d-nn65-e2b61083sd8i" // SSL certificate from the AWS Certificate Manager

</li>
</ol>

### Usage

<ol>
<li>
<strong>Initialize Terraform:</strong> Download the required provider plugins:

    terraform init

</li>
<li>
<strong>Apply Configuration:</strong> Create the resources based on the configuration:

    terraform apply -var-file="secret.tfvars"

Type `yes` to confirm the action.

</li>
<li>
<strong>Accessing the API Server:</strong> Once the Terraform apply process is complete, you can access the API server using the public IP address provided in the output. Additionally, you can access the RDS database using the endpoint provided in the output.
</li>
<li>
<strong>Destroy Resources:</strong> After you're done using the resources, you can destroy them to avoid incurring unnecessary charges:

    terraform destroy -var-file="secret.tfvars"

Type `yes` to confirm the destruction of resources.

</li>
</ol>
