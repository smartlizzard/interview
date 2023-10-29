# For get kubeconfig in your locall
aws eks update-kubeconfig --region us-east-1 --name interview-eks-cluster

# /etc/ansible/ansible.cfg
[defaults]
host_key_checking = False
private_key_file = /home/ubuntu/interview.pem
remote_user = ubuntu

# Add host in /etc/ansible/hosts
# Also we can use dynamic inventory

[nexus]
10.0.1.174
