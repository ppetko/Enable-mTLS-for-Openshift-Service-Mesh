# Enable-mTLS-for-Openshift-Service-Mesh
Enable mTLS for Openshift Service Mesh using Bookinfo as test app

![alt text](https://github.com/ppetko/Enable-mTLS-for-Openshift-Service-Mesh/blob/master/img/service-mesh-mtls.png?raw=true)

### OpenShift Version 4.3.3, SM 1.1.2

```
oc version 
Client Version: 4.3.19
Server Version: 4.3.3
Kubernetes Version: v1.16.2

```

In an OpenShift environment, a route is used to expose services outside the cluster. Through the route, traffic is directed to the service pods.

In a service mesh, a better approach is to use a gateway for incoming traffic. This allows service mesh policies and routing rules to be applied to traffic entering the service mesh.

The service mesh installs an Istio ingress gateway service, which is an Envoy proxy container running on its own. All incoming traffic into the service mesh should be routed through the Istio ingress gateway to ensure that mesh policies and routing rules are applied to incoming traffic.

To route the traffic from the ingress gateway to the target services, Gateway and VirtualService resources are defined. One way to do this is to create Gateway and VirtualService resources for each service exposed outside of the cluster. An alternative is to use a single wildcard Gateway resource along with the VirtualService resource for each service. The latter is the approach taken in this lab.

The ingress gateway also ensures end-to-end encryption for incoming traffic: TLS termination happens at the ingress gateway, and traffic is re-encrypted by the gateway using OpenShift Service Mesh mTLS functionality before routing to the service. To achieve this, the public TLS key and certificate are mounted into the ingress gateway pods using a secret.

## High-level architecture

### Security in Istio involves multiple components:

* Citadel for key and certificate management
* Sidecar and perimeter proxies to implement secure communication between clients and servers
* Pilot to distribute authentication policies and secure naming information to the proxies
* Mixer to manage authorization and auditing

![alt text](https://github.com/ppetko/Enable-mTLS-for-Openshift-Service-Mesh/blob/master/img/architecture.svg?raw=true)

### Run

```
export SUBDOMAIN_BASE=
export SM_CP_NS=bookretail-istio-system
export CP_APP=bookinfo

./deploy.sh all 
Generating a 2048 bit RSA private key
.....................................................................................................+++
..................................................+++
writing new private key to 'tls.key'
-----
Now using project "bookretail-istio-system" on server "https://api.cluster-e7c4.e7c4.sandbox1320.opentlc.com:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app django-psql-example

to build a new example application in Python. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node

servicemeshcontrolplane.maistra.io/full-install created
Now using project "bookinfo" on server "https://api.cluster-e7c4.e7c4.sandbox1320.opentlc.com:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app django-psql-example

to build a new example application in Python. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node

servicemeshmemberroll.maistra.io/default created
Error from server (AlreadyExists): project.project.openshift.io "bookinfo" already exists
service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created
gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo created
destinationrule.networking.istio.io/productpage created
destinationrule.networking.istio.io/reviews created
destinationrule.networking.istio.io/ratings created
destinationrule.networking.istio.io/details created
secret/istio-ingressgateway-certs created
deployment.extensions/istio-ingressgateway patched
gateway.networking.istio.io/bookinfo-wildcard-gateway created
policy.authentication.istio.io/productpage-policy-mtls created
destinationrule.networking.istio.io/productpage-destinationrule-mtls created
virtualservice.networking.istio.io/productpage-service-virtualservice-mtls created
route.route.openshift.io/productpage-service-gateway-mtls created
destinationrule.networking.istio.io/details-destinationrule-mtls created
policy.authentication.istio.io/details-service-mtls created
virtualservice.networking.istio.io/details-service-virtualservice-mtls created
destinationrule.networking.istio.io/ratings-destinationrule-mtls created
policy.authentication.istio.io/ratings-policy-mtls created
virtualservice.networking.istio.io/ratings-service-virtualservice-mtls created
destinationrule.networking.istio.io/reviews-destinationrule-mtls created
policy.authentication.istio.io/reviews-service-mtls created
virtualservice.networking.istio.io/reviews-service-virtualservice-mtls created

```
