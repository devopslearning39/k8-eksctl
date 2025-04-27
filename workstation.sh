#!/bin/bash

ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH


TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"

echo "script started executing at $TIMESTAMP" &>> $LOGFILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILED $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1 # you can give other than 0
else
    echo "You are root user"
fi # fi means reverse of if, indicating condition end

yum install -y yum-utils
VALIDATE $? "Installed yum utils"

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
VALIDATE $? "Added docker repo"

yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
VALIDATE $? "Installed docker components"

systemctl start docker
VALIDATE $? "Started docker"

systemctl enable docker
VALIDATE $? "Enabled docker"

usermod -aG docker centos
VALIDATE $? "added centos user to docker group"
echo -e "$R Logout and login again $N"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl
VALIDATE $? "Kubectl installation"

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
VALIDATE $? "eksctl installation"

# kubens makes namespace switching fast and easy.

sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
VALIDATE $? "kubens installation"