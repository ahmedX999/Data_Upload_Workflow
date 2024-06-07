#!/bin/bash

LAMBDA_FUNCTION_NAME="$1"
if aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" > /dev/null 2>&1; then
    echo "true"
else
    echo "false"
fi
