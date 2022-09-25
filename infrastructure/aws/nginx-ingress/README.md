Please make sure you have latest helm installed before you proceed.

helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace --values 

Deployment to SIT (System Integration Testing) / Staging Cluster
- Nginx

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

    - SIT
    helm upgrade --install ingress-nginx ingress-nginx --namespace ingress-nginx --create-namespace
    helm upgrade --install ingress-nginx-sit ingress-nginx/ingress-nginx --create-namespace --namespace ingress-nginx --values ingress-nginx-sit-values.yaml
    - Staging
    helm upgrade --install ingress-nginx-staging ingress-nginx/ingress-nginx --create-namespace --namespace ingress-nginx --values ingress-nginx-staging-values.yaml
    - Production
    helm upgrade --install ingress-nginx-prod ingress-nginx/ingress-nginx --create-namespace --namespace ingress-nginx --values ingress-nginx-prod-values.yaml

- Rabbitmq  
    helm upgrade --install rabbitmq bitnami/rabbitmq --namespace rabbitmq --create-namespace --values rabbitmq-custom-values.yaml

- Application Load Balancer
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$clustername --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

- Prometheus + Grafana
    helm upgrade --install prometheus-community prometheus-community/kube-prometheus-stack --create-namespace --namespace monitoring --values prometheus-community-custom-values