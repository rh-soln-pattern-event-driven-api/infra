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

# Check if the podman is installed
if type podman >/dev/null 2>&1; then
    echo "Podman is installed."
else
    echo "Podman is required to update developer portal Contents !"
    exit 1
fi

#  use 3scale-cms tool to upload contents to developer portal CMS
touch docs.html.liquid
touch index.html.liquid
touch  applications/show.html.liquid
touch l_main_layout.html.liquid
URL="https://webhook-apis-admin.$WILDCARD_DOMAIN"
echo "uploading contents to 3scale developer portam CMS."

podman run --rm -it -v .:/cms:Z ghcr.io/fwmotion/3scale-cms --access-token=88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512 -k  88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512 $URL upload