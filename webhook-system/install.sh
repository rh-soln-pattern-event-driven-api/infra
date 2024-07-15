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
NAMESPACE="webhook-system"

 




#get 3scale product ID

# Command to get the product ID from a Product resource
threescale_product_id=$(oc get product order-created-event -o jsonpath='{.status.productId}' -n webhook-system-3scale)

# Check if the product ID is returned and is a numeric value
if [[ ! -z "$threescale_product_id" && "$threescale_product_id" =~ ^[0-9]+$ ]]; then
    echo "Product ID is: $threescale_product_id"
    # You can add additional commands here to use the product ID
else
    echo "Failed to retrieve a valid 3scale product ID or product ID is empty."
fi



product_endpoint="https://ordercreatedevent-webhook-apis-apicast-production.$WILDCARD_DOMAIN"
echo "product_endpoint=$product_endpoint"



threescale_admin_portal_url="https://webhook-apis-admin.$WILDCARD_DOMAIN"
 echo "threescale_admin_portal_url: $threescale_admin_portal_url"
# File to modify
file_path="webhookCreator.properties"

# Single sed command to apply all changes
sed -i -e "s|^3scale.admin.portal=.*|3scale.admin.portal=$threescale_admin_portal_url|" \
        -e "s|^3scale.product.id=.*|3scale.product.id=$threescale_product_id|" \
        -e "s|^api.product.webhook.endpoint=.*|api.product.webhook.endpoint=$product_endpoint|" "$file_path"

echo "Creating webhook system Camel  quarkus deployments."
oc create secret generic webhook-creator --from-file=webhookCreator.properties -n  $NAMESPACE
oc create secret generic webhook-dispatcher --from-file=webhookDispatcher.properties -n  $NAMESPACE
oc create secret generic order-event-simulator --from-file=orderEventSimulator.properties -n  $NAMESPACE
oc create secret generic http-keystore --from-file keystore.jks -n  $NAMESPACE
oc project webhook-system


oc apply  -f 01-webhook-creator.yaml -n webhook-system
oc apply  -f 02-webhook-dispatcher.yaml -n webhook-system
oc apply  -f  03-camel-proxy.yaml -n webhook-system
oc apply  -f  04-order-event-simulator.yaml -n webhook-system
oc apply  -f 05-scaled-object.yaml -n webhook-system

echo "Deployment of Webhook delivery system has been completed."