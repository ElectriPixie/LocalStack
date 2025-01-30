#!/bin/bash
source /home/pixie/venv/spaceShip-3.12-venv/bin/activate
AWS_DEFAULT_ENDPOINT=http://localhost:4566
PATH_PART="lambda_func"

zip ../lambda/function.zip ../lambda/lambda.js
aws lambda create-function \
  --function-name apigw-lambda \
  --runtime nodejs16.x \
  --handler lambda.apiHandler \
  --memory-size 128 \
  --zip-file fileb://../lambda/function.zip \
  --role arn:aws:iam::111111111111:role/apigw
REST_API_ID=$(aws apigateway create-rest-api --name 'API Gateway Lambda integration' | jq -r '.id')
echo "REST_API_ID: "$REST_API_ID 
RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $REST_API_ID | jq -r '.items[0].id')
echo "RESOURCE_ID: "$RESOURCE_ID

SUBRESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $REST_API_ID \
  --parent-id $RESOURCE_ID \
  --path-part $PATH_PART | jq -r '.id')

echo "SUBRESOURCE_ID: "$SUBRESOURCE_ID
aws apigateway put-method \
  --rest-api-id $REST_API_ID \
  --resource-id $SUBRESOURCE_ID \
  --http-method GET \
  --request-parameters "method.request.path.somethingId=true" \
  --authorization-type "NONE"

aws apigateway put-integration \
  --rest-api-id $REST_API_ID \
  --resource-id $SUBRESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:apigw-lambda/invocations \
  --passthrough-behavior WHEN_NO_MATCH

aws apigateway create-deployment \
  --rest-api-id $REST_API_ID \
  --stage-name dev

curl -X GET http://$REST_API_ID.execute-api.localhost.localstack.cloud:4566/dev/test