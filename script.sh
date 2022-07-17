
terraform apply -auto-approve
az vmss list-instance-public-ips --name example-vmss  --resource-group azure-resource_group > file.txt
cat file.txt | grep 'ipAddress' | awk  '{print $2}' | tr -d , | sed 's/^.//;s/.$//' > ip.txt
python3 iphost.py >> host.txt
ansible-playbook -i host.txt  ansible/prot.yaml