
#!/bin/bash
set -euo pipefail

KEY_NAME="$1"
REGION="$2"
S3_BUCKET="$3"
ENVIRONMENT="$4"

S3_OBJECT_PATH="env/${ENVIRONMENT}/key-pair/${KEY_NAME}.pem"
TEMP_KEY_PATH=$(mktemp)

if ! aws ec2 describe-key-pairs --key-names "${KEY_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo "Key pair '${KEY_NAME}' not found in AWS. Creating..."

  aws ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --query 'KeyMaterial' \
    --output text \
    --region "${REGION}" > "${TEMP_KEY_PATH}"

  chmod 400 "${TEMP_KEY_PATH}"

  echo "Uploading key to S3: s3://${S3_BUCKET}/${S3_OBJECT_PATH}"
  aws s3 cp "${TEMP_KEY_PATH}" "s3://${S3_BUCKET}/${S3_OBJECT_PATH}"

  echo "Key pair created and uploaded to S3"
else
  echo "Key pair '${KEY_NAME}' exists in AWS."

  echo "Checking if key exists in S3..."
  if aws s3 ls "s3://${S3_BUCKET}/${S3_OBJECT_PATH}" >/dev/null 2>&1; then
    echo "Key already present in S3: s3://${S3_BUCKET}/${S3_OBJECT_PATH}"
  else
    echo "Error: Key exists in AWS but not found in S3. Please upload it manually."
    exit 1
  fi
fi

rm -f "${TEMP_KEY_PATH}" || true
