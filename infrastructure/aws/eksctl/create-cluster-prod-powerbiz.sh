#!/bin/bash
### prod-powerbiz
clustername=prod-powerbiz
region=prod-powerbiz
read varname
echo $clustername

echo $clustername


eksctl utils associate-iam-oidc-provider \
    --region ap-southeast-1 \
    --cluster $clustername \
    --approve


eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=public-ondemand-t3-small-ng \
                       --instance-types=t3.small \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=4 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --alb-ingress-access

#public spot
eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=public-spot-t3-small-ng \
                       --instance-types=t3.small \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=4 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --alb-ingress-access \
                       --spot

#private on demand
eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-ondemand-t3-2xlarge-ng \
                       --node-type=t3.2xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=6 \
                       --node-private-networking \
                       --subnet-ids subnet-02e99dd4a34beccc7,subnet-0a6bd7bf0180f2151 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-ondemand-r5-4xlarge-ng \
                       --node-type=r5.4xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=6 \
                       --node-private-networking \
                       --subnet-ids subnet-02e99dd4a34beccc7,subnet-0a6bd7bf0180f2151 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

#private spot
eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-spot-t3-2xlarge-ng \
                       --node-type=t3.2xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=10 \
                       --node-private-networking \
                       --subnet-ids subnet-subnet-02e99dd4a34beccc7,subnet-0a6bd7bf0180f2151 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --spot

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-spot-r5-4xlarge-ng \
                       --node-type=r5.4xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=10 \
                       --node-private-networking \
                       --subnet-ids subnet-02e99dd4a34beccc7,subnet-0a6bd7bf0180f2151 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --spot

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-spot-c5-4xlarge-ng \
                       --node-type=c5.4xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=10 \
                       --node-private-networking \
                       --subnet-ids subnet-02e99dd4a34beccc7,subnet-0a6bd7bf0180f2151 \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --spot


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

##rmq
helm 
helm upgrade --install rabbitmq bitnami/rabbitmq --create namespace --namespace rabbitmq --values rabbitmq-custom-values.yaml
echo "Username      : user" >> rabbitmq-credentials
    echo "Password      : $(kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 --decode)" >> rabbitmq-credentials
    echo "ErLang Cookie : $(kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode)" >> rabbitmq-credentials
