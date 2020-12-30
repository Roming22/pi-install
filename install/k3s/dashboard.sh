#!/bin/bash -e
#
# Maybe it should be done via ansible (https://docs.ansible.com/ansible/latest/collections/community/kubernetes/k8s_module.html)
#
set -o pipefail
SCRIPT_DIR="$(dirname $(realpath "$0"))"

dashboard(){
    # Check if anything needs to be done
    GITHUB_URL=https://github.com/kubernetes/dashboard/releases
    VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
    CURRENT_KUBE_DASHBOARD="$(kubectl get deployment.apps kubernetes-dashboard --namespace kubernetes-dashboard -o jsonpath={.spec.template.spec.containers[0].image} 2>/dev/null | cut -d: -f2 || echo "None" )"
   
    [[ "$VERSION_KUBE_DASHBOARD" != "$CURRENT_KUBE_DASHBOARD" ]] || return 0

    # Install dashboard and admin-user
    if [[ "$CURRENT_KUBE_DASHBOARD" != "None" ]]; then
        kubectl delete namespace kubernetes-dashboard
        kubectl delete clusterrole kubernetes-dashboard --namespace kubernetes-dashboard
        kubectl delete clusterrolebinding kubernetes-dashboard --namespace kubernetes-dashboard
    fi    
    kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml
    kubectl get serviceaccount admin-user --namespace kubernetes-dashboard 2>/dev/null || echo "apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard" | kubectl create -f -
    kubectl get clusterrolebinding admin-user --namespace kubernetes-dashboard 2>/dev/null || echo "apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard" | kubectl create -f -
}

token(){
    kubectl -n kubernetes-dashboard describe secret admin-user-token | grep "^token"
}

dashboard
token
echo
echo "[OK]"
