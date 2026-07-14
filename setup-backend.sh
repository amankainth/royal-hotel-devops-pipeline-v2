#!/bin/bash
# ============================================
# One-Time S3 Backend Setup for Terraform
# Run this ONCE before your first pipeline run
# ============================================

set -e

BUCKET_NAME="royal-hotel-tf-state-bucket"
TABLE_NAME="royal-hotel-tf-locks"
REGION="us-east-1"

echo "=== Bootstrapping Terraform S3 Backend ==="
echo "Bucket:   $BUCKET_NAME"
echo "Table:    $TABLE_NAME"
echo "Region:   $REGION"
echo ""

# ============================================
# S3 Bucket
# ============================================

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ S3 bucket already exists: $BUCKET_NAME"
else
    echo "Creating S3 bucket..."
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION"
    echo "✅ S3 bucket created"
fi

echo "Enabling versioning..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "Enabling encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

echo "Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# ============================================
# DynamoDB Table for Locking
# ============================================

if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null | grep -q "ACTIVE"; then
    echo "✅ DynamoDB table already exists: $TABLE_NAME"
else
    echo "Creating DynamoDB table for state locking..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"

    echo "Waiting for table to become active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
    echo "✅ DynamoDB table created"
fi

# ============================================
# Verification
# ============================================

echo ""
echo "=========================================="
echo "✅ Bootstrap complete!"
echo "=========================================="
echo ""
echo "S3 Bucket:"
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>&1 && echo "  Status: ✅ Ready"
echo "  Versioning: $(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text)"

echo ""
echo "DynamoDB Table:"
aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" --query 'Table.TableStatus' --output text | sed 's/^/  Status: /'

echo ""
echo "Next steps:"
echo "  1. Commit and push code to GitHub"
echo "  2. Run Jenkins pipeline: piple-tf-apply"
