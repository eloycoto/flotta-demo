#!/bin/bash

source ./demo-magic.sh
clear;

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

force_remove_edgedevices() {
  kubectl get edgedevices -o json --all-namespaces | jq -cr '.items[].metadata | .name + " "+.namespace' | while IFS= read obj
  do
    name=$(echo $obj | awk '{print $1}')
    ns=$(echo $obj | awk '{print $2}')

    kubectl -n $ns get edgedevice $name -o=json | jq '.metadata.finalizers = null' | kubectl -n $ns apply -f -
    kubectl -n $ns delete edgedevice $name
  done
}

run_device() {
  docker run --privileged -d --rm --name $1 -e CLIENTID=$1 --add-host project-flotta.io:192.168.2.38 -ti eloycoto/edgedevice > /dev/null
}

cleanup(){
  docker rm -f $(docker ps -a | grep "eloycoto/edgedevice" | awk '{print $1}')
  force_remove_edgedevices
  kubectl delete edsr --all
  kubectl delete ns ny
}

cleanup > /dev/null 2> /dev/null


pei "# Lets see if flotta is installed in the kubernetes cluster"
pei "kubectl api-resources | grep flotta"
pei "# Ok, all is installed, let's check if any device is up"
pei "kubectl get edsr"

run_device "camera-ny"
run_device "pos-ny"
run_device "kiosk-ny"

pei "# Ok, let's turn on some devices in the New York store"
pei "kubectl get edsr"
pei "# Let's create a namespace for NY store devices"
pei "kubectl create ns ny"
pei "# Let's approve devices in NY namespaces"
pei "kubectl patch edsr pos-ny --type='json' -p='[{\"op\": \"replace\", \"path\": \"/spec/approved\", \"value\":true}, {\"op\": \"replace\", \"path\": \"/spec/targetNamespace\", \"value\":\"ny\"}]'"
pei "kubectl patch edsr camera-ny --type='json' -p='[{\"op\": \"replace\", \"path\": \"/spec/approved\", \"value\":true}, {\"op\": \"replace\", \"path\": \"/spec/targetNamespace\", \"value\":\"ny\"}]'"
pei "kubectl patch edsr kiosk-ny --type='json' -p='[{\"op\": \"replace\", \"path\": \"/spec/approved\", \"value\":true}, {\"op\": \"replace\", \"path\": \"/spec/targetNamespace\", \"value\":\"ny\"}]'"
pei "kubectl get edgedevices -n ny"
pei "# All devices are now up!"

pei "# let's add some labels to the edgedevices"
pei "kubectl label edgedevice -n ny camera-ny app=camera"
pei "kubectl label edgedevice -n ny pos-ny app=pos"
pei "kubectl label edgedevice -n ny kiosk-ny app=kiosk"

pei "# Let's deploy now some workloads"
pei "cat x86-deploy.yaml"
pei "kubectl apply -f x86-deploy.yaml"

pei "cat camera-deploy.yaml"
pei "kubectl apply -f camera-deploy.yaml"

pei "# Now edgedevices will deploy the workloads"
pei "kubectl get -n ny edgedevice camera-ny -o json | jq '.status.workloads'"
pei "kubectl get -n ny edgedevice kiosk-ny -o json | jq '.status.workloads'"
pei "#Now your edgedevices are up&running"

kill -9 $(pgrep asciinema) /dev/null 2> /dev/null
cleanup > /dev/null 2> /dev/null


exit
