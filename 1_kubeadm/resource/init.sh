#!/bin/sh

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD
Usage: $(basename "$0") [options]
Available options:
  -p            Install POLICY
  -h            This message

Init k8s master

EOD
}

POLICY=""

# Get the options
while getopts hp c ; do
    case $c in
        p) POLICY="enabled" ;;
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

# Move token file to k8s master
TOKEN_DIR=/etc/kubernetes/auth
sudo mkdir -p $TOKEN_DIR
sudo chmod 600 $TOKEN_DIR
sudo cp -f "$DIR/tokens.csv" $TOKEN_DIR

sudo mkdir -p /etc/kubeadm
sudo cp -f $DIR/kubeadm-config*.yaml /etc/kubeadm

if [ ! -d "$HOME/k8s-exercices" ]
then
    git clone https://github.com/k8s-school/k8s-exercices.git $HOME/k8s-exercices
else
    cd "$HOME/k8s-exercices"
    git pull
fi

KUBEADM_CONFIG="/etc/kubeadm/kubeadm-config.yaml"

# Init cluster using configuration file
sudo kubeadm init --config="$KUBEADM_CONFIG"

# Manage kubeconfig
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Enable auto-completion
echo 'source <(kubectl completion bash)' >> ~/.bashrc

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubectl wait --for=condition=ready --timeout=-1s nodes "$(hostname)"

# Update kubeconfig with users alice and bob
USER=alice
kubectl config set-credentials "$USER" --token=02b50b05283e98dd0fd71db496ef01e8
kubectl config set-context $USER --cluster=kubernetes --user=$USER

USER=bob
kubectl config set-credentials "$USER" --token=492f5cd80d11c00e91f45a0a5b963bb6
kubectl config set-context $USER --cluster=kubernetes --user=$USER
