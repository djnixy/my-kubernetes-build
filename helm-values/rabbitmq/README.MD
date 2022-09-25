## SIT
helm upgrade --install rabbitmq bitnami/rabbitmq --values infrastructure/helm-values/rabbitmq/rabbitmq-custom-values.yaml --create-namespace -n rabbitmq-staging

## Ingress SIT

export RABBITMQ_PASSWORD=$(kubectl get secret --namespace "sit" rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 --decode)

export RABBITMQ_ERLANG_COOKIE=$(kubectl get secret --namespace "sit" rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode)

helm upgrade --install rabbitmq bitnami/rabbitmq --namespace sit --create-namespace --values rabbitmq-custom-values.yaml --set auth.password=$RABBITMQ_PASSWORD --set auth.erlangCookie=$RABBITMQ_ERLANG_COOKIE