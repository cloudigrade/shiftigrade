Adapted from https://github.com/daniel-rhoades/aws-ecs-autoscale-role 

aws-ecs-autoscale-role
======================

Ansible role for simplifying the provisioning and decommissioning of Auto-scaling ECS clusters within an AWS account.

For more detailed on information on the creating:

* Auto-scaling Groups: http://docs.ansible.com/ansible/ec2_asg_module.html;
* ECS Clusters: http://docs.ansible.com/ansible/ecs_cluster_module.html;
* ECS Services: http://docs.ansible.com/ansible/ecs_service_module.html;
* ECS Task Definition: http://docs.ansible.com/ansible/ecs_taskdefinition_module.html.

This role will completely setup an unlimited size, self-healing, auto-scaling EC2 cluster registered to an ECS cluster, ready to accept ECS Service and Task Definitions with centralised log management.

Requirements
------------

Requires the latest Ansible EC2 support modules along with boto, boto3, and python >= 2.6.

You will also need to configure your Ansible environment for use with AWS, see http://docs.ansible.com/ansible/guide_aws.html.

Role Variables
--------------

Defaults:

* ec2_launch_configuration_name: Name to give to the EC2 Launch Configuration for Auto-scaling purposes, defaults to `{{ ecs_cluster_name }}-lc`;
* ec2_instance_type: EC2 instance type to use in the EC2 Launch Configuration, defaults to `t2.micro`;
* ec2_ami_id: EC2 image (AMI) that contains a Docker server + ECS Agent, AWS provides a suitable default - `ami-76e95b05`;
* ec2_instance_name: Name to give to EC2 instances created during auto-scaling, default to `ecs_host`;
* ecs_instance_profile_name: IAM role ECS will use to manage EC2 instances, default will create `ecsInstanceRole` identical to the role created by AWS when creating a default cluster;
* ec2_assign_public_ip: If you want the EC2 instances to have a public IP, defaults to true;
* ec2_instance_monitoring: If you want AWS to monitor the EC2 instance for you, defaults to true;
* ec2_userdata: Script to run when an EC2 instance is provisioned for ECS use.  This is an important script;
* ec2_asg_name: Name of the Auto Scaling Group, defaults to `{{ ecs_cluster_name }}-asg`;
* ec2_asg_min_size: Minimum number of EC2 instances to keep running, defaults to 2;
* ec2_asg_max_size: Maximum number of EC2 instances to keep running, defaults to 4;
* ec2_asg_desired_capacity: Desired number of EC2 instances to keep running under normal conditions;
* ec2_asg_tags: Tags to set on any EC2 instances created as part of the auto scaling group, defaults to name=`{{ vpc_name }}_{{ ec2_instance_name }}`;
* ec2_asg_wait: Wait for EC2 instances within the auto scaling group to become available before moving on to the next task, defaults to true;
* ec2_asg_replace_all_instances: Perform a rolling update if the Launch Configuration has changed;
* ec2_asg_health_check_period: Health check interval, defaults to 60 seconds;
* ec2_asg_health_type: Method for performing the health check, defaults to EC2;
* ec2_asg_default_cooldown: Scaling cooldown period, defaults to 300 seconds;
* ecs_state: State of the ECS cluster, default to "present";
* ec2_lc_state: State of the Launch Configuration, defaults to "present";
* ec2_asg_state: State of the Auto-scaling Group, defaults to "present"

The default `ec2_userdata` will register the EC2 instance within the ECS cluster and configure the instance to stream it's logs to AWS CloudWatch Logs for centralised management.  Log Groups are pre-pended with `{{ application_name }}-{{ env }}`

Rember to control the size your cluster with default variables as listed above.

Required variables:

* ecs_cluster_name: You must specify the name of the ECS cluster, e.g. my-cluster;
* key_name: You must specify the name of the SSH key you want to assign to the EC2 instances, e.g. my-ssh-key;
* ec2_security_groups: You must specify a list of existing EC2 security groups IDs to apply to the auto-scaling EC2 instances;
* ec2_asg_availability_zones: You must specify a list of existing EC2 availability zones for which to provisioning instances into;
* ec2_asg_vpc_subnets: You must specify a list of existing VPC subnets for which to provision the EC2 nodes into.

This role depends on the existence of a VPC, subnet, security group, and ssh keys allready existing on AWS. The original author of this role has some more ansible roles that can be used to automate this, see the following roles if you would like to do so:

    * VPC to hold the ECS cluster, using the role: `daniel-rhoades.aws-vpc`;
    * EC2 Security Groups to apply to the EC2 instances, using the role: `daniel-rhoades.aws-security-group`.

License
-------

MIT
