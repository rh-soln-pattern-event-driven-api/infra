#!/bin/bash

# Retrieve the wildcard domain from the default ingress controller
WILDCARD_DOMAIN=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')

# Check if the domain was successfully retrieved
if [ -z "$WILDCARD_DOMAIN" ]; then
    echo "Failed to retrieve the wildcard domain."
    exit 1
else
    echo "The wildcard domain is: $WILDCARD_DOMAIN"
fi
export WILDCARD_DOMAIN=$WILDCARD_DOMAIN
 

# Create  namespace
oc apply -f 00-namespace.yaml
 

# Define the namespace
NAMESPACE="webhook-system-shipping-consumer"

oc apply -f webhook-consumer-shipping.yaml -n $NAMESPACE
 



