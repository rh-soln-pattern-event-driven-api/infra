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
  
 

# Define the namespace
NAMESPACE="webhook-system-3scale"

apiURLprefix="https://webhook-apis-admin.${WILDCARD_DOMAIN}/admin/api"
accessToken="88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512"
  


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
