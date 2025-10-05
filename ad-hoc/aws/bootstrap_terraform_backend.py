import argparse
import boto3
from botocore.exceptions import ClientError
import time


def create_s3_bucket(s3_client, bucket_name, region):
    """
    Creates an S3 bucket and enables versioning on it.

    Args:
        s3_client: The initialized boto3 S3 client.
        bucket_name (str): The name for the S3 bucket.
        region (str): The AWS region for the bucket.
    """
    print(f"Attempting to create S3 bucket: {bucket_name} in {region}...")
    try:
        if region == 'us-east-1':
            # us-east-1 is the default region and does not require a LocationConstraint
            s3_client.create_bucket(Bucket=bucket_name)
        else:
            s3_client.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={'LocationConstraint': region}
            )
        print(f"✅ S3 Bucket '{bucket_name}' created successfully.")

        # Enable versioning (crucial for state rollback protection)
        s3_client.put_bucket_versioning(
            Bucket=bucket_name,
            VersioningConfiguration={'Status': 'Enabled'}
        )
        print("✅ S3 Bucket Versioning enabled.")

        # Best practice: Block all public access
        s3_client.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )
        print("✅ S3 Bucket Public Access Block configured.")


    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'BucketAlreadyOwnedByYou':
            print(f"⚠️ S3 Bucket '{bucket_name}' already exists and is owned by you. Skipping creation.")
        elif error_code == 'InvalidLocationConstraint':
            print(f"❌ Error: Invalid location constraint for region '{region}'. Check your region name.")
            return
        else:
            print(f"❌ Error creating S3 bucket: {e}")
            return


def create_dynamodb_table(dynamodb_client, table_name, region):
    """
    Creates a DynamoDB table with 'LockID' as the primary key.

    Args:
        dynamodb_client: The initialized boto3 DynamoDB client.
        table_name (str): The name for the DynamoDB table.
        region (str): The AWS region for the table.
    """
    print(f"\nAttempting to create DynamoDB table: {table_name} in {region}...")
    try:
        dynamodb_client.create_table(
            TableName=table_name,
            KeySchema=[
                {
                    # Terraform requires the Partition Key to be named exactly 'LockID'
                    'AttributeName': 'LockID',
                    'KeyType': 'HASH'  # Partition key
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'LockID',
                    'AttributeType': 'S'  # String type
                }
            ],
            # Use PAY_PER_REQUEST for cost efficiency during low usage
            BillingMode='PAY_PER_REQUEST'
        )

        print(f"⏳ Waiting for DynamoDB table '{table_name}' to become active...")
        waiter = dynamodb_client.get_waiter('table_exists')
        waiter.wait(TableName=table_name)

        print(f"✅ DynamoDB Table '{table_name}' created and active.")

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ResourceInUseException':
            print(f"⚠️ DynamoDB Table '{table_name}' already exists. Skipping creation.")
        else:
            print(f"❌ Error creating DynamoDB table: {e}")
            return


def main():
    """
    Main function to parse arguments and call creation functions.
    """
    parser = argparse.ArgumentParser(
        description="Provision an S3 bucket and DynamoDB table for Terraform remote state management."
    )
    parser.add_argument(
        '--bucket-name',
        required=True,
        help="Globally unique name for the S3 bucket (e.g., myorg-tf-state-1234)"
    )
    parser.add_argument(
        '--table-name',
        required=True,
        help="Name for the DynamoDB locking table (e.g., terraform-state-lock)"
    )
    parser.add_argument(
        '--region',
        default='us-east-1',
        help="AWS region where resources should be created (e.g., us-west-2). Default: us-east-1"
    )

    args = parser.parse_args()

    # Initialize Boto3 clients. Boto3 will automatically look for credentials
    # in environment variables, AWS CLI config, or IAM roles.
    try:
        s3_client = boto3.client('s3', region_name=args.region)
        dynamodb_client = boto3.client('dynamodb', region_name=args.region)
    except Exception as e:
        print(f"❌ Failed to initialize AWS clients. Ensure your AWS credentials are configured properly.\nError: {e}")
        return

    # Provision resources
    create_s3_bucket(s3_client, args.bucket_name, args.region)
    create_dynamodb_table(dynamodb_client, args.table_name, args.region)

    # Final Configuration Summary
    print("\n" + "=" * 50)
    print("🚀 Terraform Backend Bootstrap Complete 🚀")
    print(f"Region: {args.region}")
    print(f"S3 Bucket: {args.bucket_name} (Versioning/Encryption Enabled)")
    print(f"DynamoDB Table: {args.table_name} (Primary Key: LockID)")
    print("=" * 50)

    # Output the Terraform backend configuration block for convenience
    print("\nCopy the following block into your Terraform configuration (e.g., `backend.tf`):")
    print("```hcl")
    print("terraform {")
    print('  backend "s3" {')
    print(f'    bucket         = "{args.bucket_name}"')
    print('    key            = "path/to/your/state/terraform.tfstate"')
    print(f'    region         = "{args.region}"')
    print(f'    dynamodb_table = "{args.table_name}"')
    print('    encrypt        = true')
    print('  }')
    print("}")
    print("```")
    print("\nRun 'terraform init' in your project directory to finalize the remote state setup.")


if __name__ == "__main__":
    main()
