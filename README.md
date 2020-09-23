# eha
Setup env on aws 
This terraform script does the following:
  build 4 ec2 instances on aws on 2 AZ's.
  deploy 2 types of docker containers Nginx and simple-web app 1 container per instance. 
  set up ALB in aws
  
If successfully executed - you will be able to access using the ALB ip to the 2 types of containers.
  using host mynginx.com - to the nginx.
  using host myapp.com - the the simple-web app.
  
Prerequisites for the server running this terraform:

  Terraform ( v0.13.3 ) 
  Ansible  (2.9.13) 
  boto3 (1.15.3)
  botocore (1.18.3)
  
Setup the AWS account info:

  export aws_access_key="xxxxxxxxxxxxxxxxxxxxxx"
  export aws_secret_key="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  export private_key_path="xxxxxxxxxxxxxxx"
  export AWS_REGION="region"


Execute:

  cd <path to the tf script>
  terraform init
  terraform plan
  terraform apply



