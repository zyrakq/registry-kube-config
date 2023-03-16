werf-convert:
  kompose convert -f docker-compose.yml -o ./.helm/templates;
  rm ./.helm/templates/*-persistentvolumeclaim.yaml;
  find ./.helm/templates -type f -exec sed -i "s/'{{{{ \(.*\) }}'/{{{{ \1 }}/g" {} +;
  mv .helm/templates/*-configmap.yaml .kube;
  mv .helm/templates/*-secret.yaml .kube;

werf-encrypt:
  werf helm secret values encrypt .raw/secret-values.yaml -o .helm/secret-values.yaml;
  werf helm secret file encrypt ".raw/config.yaml" -o ".helm/config/config.yaml";
  werf helm secret file encrypt ".raw/htpasswd" -o ".helm/secret/htpasswd";
  werf helm secret file encrypt ".raw/registry-auth-client-secret.yaml" -o ".helm/secret/registry-auth-client-secret.yaml";
werf-decrypt:
  werf helm secret values decrypt .helm/secret-values.yaml -o .raw/secret-values.yaml;
  werf helm secret file encrypt ".helm/config/config.yaml" -o ".raw/config.yaml";
  werf helm secret file encrypt ".helm/secret/htpasswd" -o ".raw/htpasswd";
  werf helm secret file encrypt ".helm/secret/registry-auth-client-secret.yaml" -o ".raw/registry-auth-client-secret.yaml";

werf-up-storage:
  kubectl apply -f local-storage.yaml;
  kubectl apply -f registry-pv-0.yaml;
werf-down-storage:
  kubectl delete -f registry-pv-0.yaml;
  kubectl delete -f local-storage.yaml;

werf-up-conf:
  kubectl create namespace registry &>/dev/null || exit 0;
  kubectl config set-context --current --namespace=registry;
  cp .raw/registry-auth-client-secret.yaml .kube/registry-auth-client-secret.yaml;
  kubectl apply -Rf ./.kube/;
werf-down-conf:
  kubectl apply -Rf ./.kube/;

werf-up:
  werf converge;
werf-down:
  werf dismiss;
  
werf-clear:
  werf dismiss;
  kubectl delete namespace keycloak;
  kubectl delete -f registry-pv-0.yaml;
  kubectl delete -f local-storage.yaml;
  