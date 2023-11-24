# terraform-apstra-lab
Terraform Apstra LAB


Quick Ubuntu install:
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install -y terraform
```


```bash
#################################################
### NOTE: Terraform Debug Enable
# bash>
# export TF_LOG=”DEBUG”
# export TF_LOG_PATH="${PWD}/terraform-debug.log"
# echo $TF_LOG
# echo $TF_LOG_PATH
# unset TF_LOG
# unset TF_LOG_PATH
#################################################
```