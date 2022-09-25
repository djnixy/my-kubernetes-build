clustername=test2
region=ap-southeast-1
awsaccountid=939923956045
echo $awsaccountid
echo $clustername
echo $region

#eksctl create cluster
eksctl create cluster --name=$clustername \
                      --region=$region \
                      --version=1.21 \
                      --without-nodegroup 

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
helm repo add ingress-nginx/ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update


kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
    --set clusterName=$clustername \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --values ingress-nginx-custom-values.yaml

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=spot-t3-medium-ng1 \
                       --instance-types=t3.medium \
                       --nodes=1 \
                       --nodes-min=1 \
                       --nodes-max=4 \
                       --node-labels="app-deployment=false,db-deployment=false,monitoring-deployment=true" \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --alb-ingress-access \
                       --spot

eksctl create nodegroup --cluster=$clustername \
                       --region=$region \
                       --name=spot-t3-medium-ng2 \
                       --instance-types=t3.medium \
                       --nodes=1 \
                       --nodes-min=1 \
                       --nodes-max=4 \
                       --node-labels="app-deployment=true,db-deployment=false,monitoring-deployment=false" \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --alb-ingress-access \
                       --spot

aws eks update-kubeconfig --name $clustername --alias $clustername

##cleanup
