##### beta-powerbiz ###


awsaccountid=165232864651

clustername=test
region=ap-southeast-1

echo $awsaccountid
echo $clustername
echo $region

##Create VPC from template
stackID=$(aws cloudformation create-stack \
  --template-body file://cloudformation-eks-vpc-public-private-subnets.yaml \
  --stack-name alpha-powerbiz \
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
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
    --set clusterName=$clustername \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

#public on demand

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=public-ondemand-t3-small-ng \
                       --instance-types=t3.small \
                       --node-ami-family Bottlerocket \
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
                       --nodes=1 \
                       --nodes-min=1 \
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
                       --subnet-ids subnet-0c5e27b6fc964ee15,subnet-050ae6cf92c673cfe \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-ondemand-r6i-4xlarge-ng \
                       --node-type=r6i.4xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=6 \
                       --node-private-networking \
                       --subnet-ids subnet-0c5e27b6fc964ee15,subnet-050ae6cf92c673cfe \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-ondemand-c6i-4xlarge-ng \
                       --node-type=c6i.4xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=6 \
                       --node-private-networking \
                       --subnet-ids subnet-0c5e27b6fc964ee15,subnet-050ae6cf92c673cfe \
                       --managed \
                       --node-labels="application-node=true,staging-node=true,ondemand-instance=true" \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-ondemand-c6i-2xlarge-ng \
                       --node-type=c6i.2xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=6 \
                       --node-private-networking \
                       --subnet-ids subnet-0c5e27b6fc964ee15,subnet-050ae6cf92c673cfe \
                       --managed \
                       --node-labels="application-node=true,staging-node=true,ondemand-instance=true" \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-ondemand-m6i-4xlarge-ng \
                       --node-type=m6i.4xlarge \
                       --node-ami-family Bottlerocket \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=10 \
                       --node-private-networking \
                       --subnet-ids subnet-0c5e27b6fc964ee15,subnet-050ae6cf92c673cfe \
                       --managed \
                       --node-labels="application-node=true,staging-node=true,ondemand-instance=true" \
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
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --spot

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-spot-c6i-4xlarge-ng \
                       --node-type=c6i.4xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=6 \
                       --node-private-networking \
                       --managed \
                       --node-labels="application-node=true,staging-node=true,spot-instance=true" \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --spot

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=private-spot-c6i-2xlarge-ng \
                       --node-type=c6i.2xlarge \
                       --nodes=0 \
                       --nodes-min=0 \
                       --nodes-max=6 \
                       --node-private-networking \
                       --managed \
                       --node-labels="application-node=true,staging-node=true,spot-instance=true" \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --spot

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --node-ami-family Bottlerocket \
                       --name=private-spot-m6i-xlarge \
                       --node-type=m6i.large \
                       --nodes=4 \
                       --nodes-min=4 \
                       --nodes-max=10 \
                       --node-private-networking \
                       --managed \
                       --node-labels="application-node=true,staging-node=true,spot-instance=true" \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --spot


eksctl create fargateprofile \
    --cluster $clustername \
    --name fargate-dev \
    --namespace fargate-dev \
    --labels fargate="true"

eksctl create fargateprofile \
    --cluster beta-powerbiz \
    --name fargate-dev \
    --namespace fargate-dev \
    --labels fargate="true"

eksctl delete fargateprofile \
    --cluster beta-powerbiz \
    --name fargate-dev

eksctl create fargateprofile \
    --cluster beta-powerbiz \
    --name ns-staging \
    --namespace staging \
    --labels runon=fargate

eksctl delete fargateprofile \
    --cluster beta-powerbiz \
    --name ns-staging

eksctl create fargateprofile \
    --cluster beta-powerbiz \
    --name ns-core \
    --namespace core \
    --labels fargate="true"


aws eks update-kubeconfig --name $clustername


