#!/bin/bash

if [ $UID != 0 ]
then echo please run as root
     exit 1
fi

set -e

function add_ssh_key() {
   mkdir -p /home/$user/.ssh
   chown -Rf $user:$user /home/$user/.ssh
   chmod 700 /home/$user/.ssh

   read -p "please enter a SSH Key to add or enter to skip: " ssh_key

   if [ -n "$ssh_key" ]
   then echo "$ssh_key" >> /home/$user/.ssh/authorized_keys
        chmod 600 /home/$user/.ssh/authorized_keys
   fi
}

unset yn
read -p "setup users? y[N]: " yn

if [[ $yn == [Yy] ]]
then while true
     do unset user
        read -p "please enter a username to add or just hit enter to continue: " user
        [ -z "$user" ] && break
        if [ ! -d /home/$user ]
        then useradd $user
        else echo $user already exists
        fi
        add_ssh_key
     done
fi

unset yn
read -p "users all setup, install packages? y[N]: " yn

if [[ $yn == [Yy] ]]
then # General Things to install
     yum check-update
     yum install epel-release  # The extended official repository
     yum install git wget curl python3-pip nginx firewalld 
     systemctl start firewalld
     firewall-cmd --permanent --add-service=ssh
     systemctl reload firewalld
     
     # Kops and Kubectl
     # https://github.com/kubernetes/kops/blob/master/docs/install.md
     wget -O /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
     chmod +x /usr/local/bin/kops
     
     wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
     chmod +x /usr/local/bin/kubectl
     
     # AWS CLI
     pip install awscli
     
     # Gitlab Installation
     yum install -y curl policycoreutils-python openssh-server
     systemctl enable sshd
     systemctl start sshd
     firewall-cmd --permanent --add-service=http
     firewall-cmd --permanent --add-service=https

     systemctl reload firewalld
     
     yum install postfix
     systemctl enable postfix
     systemctl start postfix
     curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
     while true
     do unset gitlab_hostname yn
        read -p "Please enter your gitlab hostname" gitlab_hostname
        read -p "gitlab_hostname:$gitlab_hostname, is this correct? y[N]: " yn
        if [[ $yn == [Yy] ]]
        then break
        fi
     done
     sudo EXTERNAL_URL="http://$gitlab_hostname" yum install -y gitlab-ee
     
     # Docker setup
     curl -fsSL https://get.docker.com/ | sh
     systemctl start docker
     systemctl status docker
     systemctl enable docker

     # Artifactory
     wget https://bintray.com/jfrog/artifactory-rpms/rpm -O /etc/yum.repos.d/bintray-jfrog-artifactory-rpms.repo
     yum install jfrog-artifactory-oss
fi
