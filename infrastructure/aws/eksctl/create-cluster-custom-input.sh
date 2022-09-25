#!/bin/bash
### prod-powerbiz
clustername=prod-powerbiz
region=ap-southeast-1
nodetypepriv
nodetypepub

read clustername
read region
read nodetypepriv
read privnodecount
read nodetypepub
read pubnodecount

echo $clustername
echo $region




eksctl utils associate-iam-oidc-provider \
    --region region \
    --cluster $clustername \
    --approve

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=public-nodegroup-1 \
                       --node-type=$nodetypepub \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=10 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --alb-ingress-access


eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-nodegroup-1 \
                       --node-type=$nodetypepriv \
                       --nodes=2 \
                       --nodes-min=2 \
                       --nodes-max=10 \
                       --node-private-networking \
                       --subnet-ids subnet-02e99dd4a34beccc7,subnet-0a6bd7bf0180f2151 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

#Install aws load balancer
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json

eksctl create iamserviceaccount \
--cluster=$clustername \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::165232864651:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$clustername --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

aws eks update-kubeconfig --name $clustername



##### beta-powerbiz ###





awsaccountid=165232864651

clustername=beta-powerbiz
region=ap-southeast-1

echo $awsaccountid
echo $clustername
echo $region

##Create VPC from template
stackID=$(aws cloudformation create-stack \
  --template-url https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml \
  --stack-name beta-powerbiz \
  --parameters ParameterKey=VpcBlock,ParameterValue=10.199.0.0/16 \
                ParameterKey=PublicSubnet01Block,ParameterValue=10.199.0.0/18 \
                ParameterKey=PublicSubnet02Block,ParameterValue=10.199.64.0/18 \
                ParameterKey=PrivateSubnet01Block,ParameterValue=10.199.128.0/18 \
                ParameterKey=PrivateSubnet02Block,ParameterValue=10.199.192.0/18 \
  --tags Key=env,Value=dev Key=env2,Value=dev2 --query StackId --output text)
echo $stackID
vpc=$(aws cloudformation describe-stacks --stack-name beta-powerbiz --query Stacks[].Outputs[1].OutputValue --output text)
publicsnet01=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=$clustername-PublicSubnet01 --query Subnets[].SubnetId --output text)
publicsnet02=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=$clustername-PublicSubnet02 --query Subnets[].SubnetId --output text)
privatesnet01=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=$clustername-PrivateSubnet01 --query Subnets[].SubnetId --output text)
privatesnet02=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=$clustername-PrivateSubnet02 --query Subnets[].SubnetId --output text)

#eksctl create cluster
eksctl create cluster --name=$clustername \
                      --region=$region \
                      --vpc-private-subnets=privatesnet01,privatesnet02 \
                      --vpc-public-subnets=publicsnet01,publicsnet02 \
                      --without-nodegroup 

                      eksctl create cluster \


#aws cloudformation describe-stacks --stack-name beta-powerbiz --query Stacks[].StackId

eksctl utils associate-iam-oidc-provider \
    --region $region \
    --cluster $clustername \
    --approve

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=public-nodegroup-1 \
                       --node-type=t3.small \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=10 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --alb-ingress-access


eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-nodegroup-1 \
                       --node-type=t3.2xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=10 \
                       --node-private-networking \
                       --subnet-ids subnet-0c5e27b6fc964ee15,subnet-050ae6cf92c673cfe \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json

eksctl create iamserviceaccount \
--cluster=$clustername \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::$awsaccountid:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$clustername --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

aws eks update-kubeconfig --name $clustername



##rmq
helm 
helm upgrade --install rabbitmq bitnami/rabbitmq --create namespace --namespace rabbitmq --values rabbitmq-custom-values.yaml
echo "Username      : user" >> rabbitmq-credentials
    echo "Password      : $(kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 --decode)" >> rabbitmq-credentials
    echo "ErLang Cookie : $(kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode)" >> rabbitmq-credentials
