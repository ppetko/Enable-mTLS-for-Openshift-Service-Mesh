#!/bin/bash

DATE=`date +%Y-%m-%d-%H:%M:%S`
SUBDOMAIN_BASE=${SUBDOMAIN_BASE:-foobar}
SM_CP_NS=${SM_CP_NS:-foo}
CP_APP=${CP_APP:-bar}
MAXWAIT=10

function log(){
    echo "$DATE $@" 
    return 0
}

function warn(){
    echo "$DATE $@" 
    return 1
}

function panic(){
    echo "$DATE $@" 
    exit 1
}

function generateCerts (){
    echo "
    [ req ]
    req_extensions     = req_ext
    distinguished_name = req_distinguished_name
    prompt             = no

    [req_distinguished_name]
    commonName=.apps.$SUBDOMAIN_BASE

    [req_ext]
    subjectAltName   = @alt_names

    [alt_names]
    DNS.1  = apps.$SUBDOMAIN_BASE
    DNS.2  = *..apps.$SUBDOMAIN_BASE
    " > cert.cfg

    if [ -z "${SUBDOMAIN_BASE}" ]; then
	    panic "Openshift subdomain is not set" 
    fi

    openssl req -x509 -config ./cert.cfg -extensions req_ext -nodes -days 730 -newkey rsa:2048 -sha256 -keyout tls.key -out tls.crt
}

function deployServicemesh(){
   
    ### Create NS for SM Control Plane
    oc new-project "${SM_CP_NS}"

    ### Install Service Mesh Control Plane 
    oc apply -f ServiceMeshControlPlane.yaml

    ### Create NS for bookinfo app
    oc new-project "${CP_APP}"

    ### Install Service Mesh Member Roll
    oc apply -f ServiceMeshMemberRoll.yaml

    sleep 60
}

function deployBookinfo(){

    oc new-project "${CP_APP}"
		
    oc apply -n "${CP_APP}" -f https://raw.githubusercontent.com/Maistra/istio/maistra-1.1/samples/bookinfo/platform/kube/bookinfo.yaml

    oc apply -n "${CP_APP}" -f https://raw.githubusercontent.com/Maistra/istio/maistra-1.1/samples/bookinfo/networking/bookinfo-gateway.yaml

    export GATEWAY_URL=$(oc -n ${SM_CP_NS} get route istio-ingressgateway -o jsonpath='{.spec.host}')

    oc apply -n "${CP_APP}" -f https://raw.githubusercontent.com/Maistra/istio/maistra-1.1/samples/bookinfo/networking/destination-rule-all.yaml

    echo $GATEWAY_URL

    sleep 60

}

function mTLS(){

    ### Create secret 
    oc create secret tls istio-ingressgateway-certs --cert tls.crt --key tls.key -n $SM_CP_NS
    oc patch deployment istio-ingressgateway \
	-p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date +%FT%T%z`'"}}}}}' -n  $SM_CP_NS

    ### Define Wildcard Gateway
    oc create -f wildcard-gateway.yml -n $SM_CP_NS


    ### Setup Product Page Service
    oc create -f productpage-policy.yml -n $CP_APP
    oc create -f productpage-destinationrule.yml -n $CP_APP
    oc create -f productpage-virtualservice.yml -n $CP_APP
    oc create -f productpage-gateway.yml -n $SM_CP_NS

    ### Setup Details Service 
    oc create -f details-destinationrule.yml -n $CP_APP
    oc create -f details-service-policy.yml -n $CP_APP
    oc create -f details-virtualservice.yml -n $CP_APP

    ### Setup Ratings Service
    oc create -f ratings-destinationrule.yml -n $CP_APP
    oc create -f ratings-policy.yaml -n $CP_APP
    oc create -f ratings-virtualservice.yml -n $CP_APP 

    ### Setup Reviews Service
    oc create -f reviews-destinationrule.yml -n $CP_APP
    oc create -f reviews-policy.yml -n $CP_APP 
    oc create -f reviews-virtualservice.yml -n $CP_APP
}

function all(){
    generateCerts
    deployServicemesh
    sleep $((RANDOM % MAXWAIT))
    deployBookinfo
    sleep $((RANDOM % MAXWAIT))
    mTLS

}

case $1 in
    generateCerts)
      generateCerts
      ;;
    deployServicemesh)
      deployServicemesh
      ;;
    deployBookinfo)
      deployBookinfo
      ;;
    mTLS)
      mTLS
      ;;
    all)
      all
      ;;
  *)
    log "Usage: $0 <generateCerts|deployServicemesh|deployBookinfo|mTLS|all>"
esac

