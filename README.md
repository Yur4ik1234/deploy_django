
# deploy_inf_syst

It is a project of automation deploying service.

## What I use

- Terraform for creation infrasrtucture
- Azure as a Terraform provider
- Ansible playbooks for configuration managment 

In *main.tf* creates all infrastructure. 
in **script.sh** managing all deployment 
1. In first line applying terraform infrastructure 
2. Second line is getting public ip from each o machine of vm scale set
3. Next two lines were made for pasting ip addresses to inventory file for deploying django app on each vm
4. The last one step is running playbook **prot.yml** in each machine and deploying app. 

