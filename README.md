# AWS Advanced IAM Governance Lab (Permissions Boundaries)

This lab demonstrates a mission-critical governance pattern for the **AWS SysOps Administrator Associate**: implementing delegated administration while preventing privilege escalation using **IAM Permissions Boundaries**.

## Architecture Overview

The system implements a secure, three-tier governance model:

1.  **Permissions Boundary:** A managed IAM policy (\`StandardUserPermissionsBoundary\`) that acts as a "hard limit." No user or role managed under this boundary can ever exceed these permissions, even if they have an \`AdministratorAccess\` policy attached.
2.  **Delegated Administrator:** An IAM role (\`junior-cloud-admin-role\`) granted the ability to create new IAM roles for application teams.
3.  **Mandatory Enforcement:** Using IAM Conditions, the delegated administrator is restricted from creating any role unless they explicitly attach the Permissions Boundary to the new role.
4.  **Escalation Prevention:** This ensures the "Junior Admin" cannot create a role with more power than allowed, effectively neutralizing the risk of privilege escalation within the account.

## Key Components

-   **IAM Permissions Boundary:** The policy that defines the maximum "blast radius."
-   **IAM Conditions:** The logic that mandates the boundary during role creation.
-   **Delegated Admin Role:** The identity representing a team with restricted administrative capabilities.

## Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html)
-   [LocalStack Pro](https://localstack.cloud/)
-   [AWS CLI / awslocal](https://github.com/localstack/awscli-local)

## Deployment

1.  **Initialize and Apply:**
    ```bash
    terraform init
    terraform apply -auto-approve
    ```

## Verification & Testing

To test the IAM governance and boundary enforcement:

1.  **Verify Boundary Policy:**
    ```bash
    awslocal iam get-policy --policy-arn <YOUR_BOUNDARY_ARN>
    aws iam get-policy --policy-arn <YOUR_BOUNDARY_ARN>
    ```

2.  **Test Restricted Role Creation (Conceptual):**
    If you assume the \`junior-cloud-admin-role\`, attempting to create a role *without* the boundary will result in an \`AccessDenied\` error.

3.  **Confirm Escalation Protection:**
    Even if a role created by the Junior Admin has \`Allow: *\`, it will still be restricted by the \`StandardUserPermissionsBoundary\`.

## Cleanup

To tear down the infrastructure:
```bash
terraform destroy -auto-approve
```

---

💡 **Pro Tip: Using `aws` instead of `awslocal`**

If you prefer using the standard `aws` CLI without the `awslocal` wrapper or repeating the `--endpoint-url` flag, you can configure a dedicated profile in your AWS config files.

### 1. Configure your Profile
Add the following to your `~/.aws/config` file:
```ini
[profile localstack]
region = us-east-1
output = json
# This line redirects all commands for this profile to LocalStack
endpoint_url = http://localhost:4566
```

Add matching dummy credentials to your `~/.aws/credentials` file:
```ini
[localstack]
aws_access_key_id = test
aws_secret_access_key = test
```

### 2. Use it in your Terminal
You can now run commands in two ways:

**Option A: Pass the profile flag**
```bash
aws iam create-user --user-name DevUser --profile localstack
```

**Option B: Set an environment variable (Recommended)**
Set your profile once in your session, and all subsequent `aws` commands will automatically target LocalStack:
```bash
export AWS_PROFILE=localstack
aws iam create-user --user-name DevUser
```

### Why this works
- **Precedence**: The AWS CLI (v2) supports a global `endpoint_url` setting within a profile. When this is set, the CLI automatically redirects all API calls for that profile to your local container instead of the real AWS cloud.
- **Convenience**: This allows you to use the standard documentation commands exactly as written, which is helpful if you are copy-pasting examples from AWS labs or tutorials.
