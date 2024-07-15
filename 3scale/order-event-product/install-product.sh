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
 export staging_url="https://ordercreatedevent-webhook-apis-apicast-staging.${WILDCARD_DOMAIN}"
 export production_url="https://ordercreatedevent-webhook-apis-apicast-production.${WILDCARD_DOMAIN}"
yq eval '.spec.deployment.apicastHosted.stagingPublicBaseURL=env(staging_url)' -i 02-order-created-event-product.yaml
yq eval '.spec.deployment.apicastHosted.productionPublicBaseURL=env(production_url)' -i 02-order-created-event-product.yaml

echo "Creating API Product."
# Create 3scale namespace
oc apply -f 01-3scale-backend.yaml
oc apply -f 02-order-created-event-product.yaml
oc apply -f 03-openapi-secret.yaml
oc apply -f 04-activedoc.yaml
oc apply -f 05-proxy-configs.yaml


# Define the namespace
NAMESPACE="webhook-system-3scale"

apiURLprefix="https://webhook-apis-admin.${WILDCARD_DOMAIN}/admin/api"
accessToken="88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512"

# add custom field for webhook url in the Application
export url="$apiURLprefix/fields_definitions.json"
#echo "url=$url"
curl -k -X 'POST' "$url" -H 'accept: */*' -H 'Content-Type: application/x-www-form-urlencoded' -d 'access_token=88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512&target=Cinstance&name=webhook-url&label=Webhook%20URL&required=true&hidden=false&read_only=false'





# URL from which to fetch the services JSON data
url="$apiURLprefix/services.json?access_token=$accessToken"

# Use curl to fetch the data and jq to parse it to get the first matching service's ID
service_id=$(curl -s "$url" | jq -r '.services[] | select(.service.name == "API") | .service.id | select(. != null) ')

# Check if a service/product ID of default API Product was found and delete  it
if [ -n "$service_id" ]; then
    echo "Service ID for the first service named 'API': $service_id"
    url="$apiURLprefix/services/$service_id.json?access_token=$accessToken"
    # Send DELETE request using curl
    response=$(curl -X 'DELETE' "$url" -H 'accept: */*' -s) 
    echo "response of delete API Product: $response"   

else
    echo "No service found with the name 'API'."
fi

url="$apiURLprefix/application_plans.json?access_token=$accessToken"

# Use curl to get the application plan ID of unlimited notifications
application_plan_id=$(curl -s "$url" | jq -r '.plans[] | select(.application_plan.name == "Unlimited notifications") | .application_plan.id | select(. != null) ')

url="$apiURLprefix/accounts.json?access_token=$accessToken"

# Use curl to get default Developer Account Id
account_id=$(curl -s "$url" | jq -r '.accounts[] | select(.account.org_name == "Developer") | .account.id | select(. != null) ')

echo "account_id=$account_id application_plan_id=$application_plan_id"

# Create developer application for testing
if [[ $application_plan_id ]] && [[ $account_id ]]; then
    url="$apiURLprefix/accounts/$account_id/applications.json"
      response=$(curl -X 'POST' "$url" -H 'accept: */*'   -d "name=shipping-unlimited-application&&plan_id=$application_plan_id&description=unlimited%20application%20for%20order%20created%20event&access_token=$accessToken" -s) 
      echo "response of creating application $response"
fi
