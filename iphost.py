myfile = open ("ip.txt","rt")
contents = myfile.readlines()

for line in contents:
    print (line.replace("\n","")+ " ansible_become=yes ansible_ssh_user=adminuser ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_python_interpreter=/usr/bin/python3")