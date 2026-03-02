# Azure Policy IaC Remediation — Training Guide

This guide walks you through using this repository to learn Azure Policy fundamentals with Terraform. You will deploy a resource group, assign the NIST SP 800-53 Rev. 5 compliance initiative, deploy a storage account to observe compliance evaluation, and then apply a custom policy to enforce storage account naming rules.

---

## Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (>= 1.0)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (latest)
- An Azure subscription with permissions to create resources and assign policies

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repo-url>
cd Azure-Policy-IaC-Remediation
```

### 2. Authenticate to Azure

Log in to Azure and set your target subscription:

```bash
az login
az account set --subscription "<your-subscription-id>"
```

Verify you are on the correct subscription:

```bash
az account show --output table
```

### 3. Configure Variables

Navigate to the dev environment directory and create your `terraform.tfvars` file:

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to set values appropriate for your environment:

```hcl
environment_prefix = "dev"
workload           = "AzurePolicyDemo"
location           = "eastus"
data_location      = ""

tags = {
  Project    = "Azure Policy Sample"
  Owner      = "Platform Team"
  CostCenter = "Engineering"
}
```

### 4. Initialize Terraform

From the `terraform/environments/dev` directory, initialize the project:

```bash
terraform init
```

This downloads the required providers (`azurerm`, `random`) and initializes all modules.

---

## Step 1 — Deploy the Resource Group and NIST Policy Initiative

In this first step, you deploy only the resource group and the NIST SP 800-53 Rev. 5 policy initiative assignment. The storage account and custom policy should not be deployed yet.

### Comment Out the Storage Account and Custom Policy

Open `terraform/project/main.tf` and comment out the **Storage Account** and **Custom Policy** module blocks so that only the resource group and NIST policy initiative remain active:

```hcl
# Resource Group
module "resource_group" {
  source = "../modules/azurerm/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# NIST SP 800-53 Rev. 5 Policy Initiative Assignment
module "nist_sp_800_53_r5_policy" {
  source = "../modules/azurerm/policy_assignment"

  name                     = "NIST SP 800-53 R5"
  resource_group_id        = module.resource_group.id
  location                 = var.location
  policy_set_definition_id = local.nist_sp_800_53_r5_initiative_id
  enforcement_mode         = var.policy_enforcement_disabled
  tags                     = var.tags
}

# ---------------------------------------------------------------
# COMMENT OUT EVERYTHING BELOW FOR STEP 1
# ---------------------------------------------------------------

# # Storage Account
# module "storage_account" {
#   source = "../modules/azurerm/storage_account"
#
#   name                = replace(local.storage_account_name, "-", "")
#   resource_group_name = module.resource_group.name
#   location            = var.location
#   tags                = var.tags
# }

# # Custom Policy - Storage Account Name Max Length
# module "storage_name_length_policy" {
#   source = "../modules/azurerm/custom_policy"
#
#   policy_name         = "Custom-storage-name-max-length"
#   policy_display_name = "Storage account name must not exceed 10 characters"
#   policy_description  = "Denies creation of storage accounts whose name exceeds 10 characters."
#   resource_group_id   = module.resource_group.id
#   location            = var.location
#   max_name_length     = 10
#   resource_type       = "Microsoft.Storage/storageAccounts"
#   enforcement_mode    = var.policy_enforcement_disabled
#   tags                = var.tags
# }
```

You will also need to comment out the corresponding outputs in `terraform/project/outputs.tf` that reference the commented-out modules. Comment out any output blocks that reference `module.storage_account` or `module.storage_name_length_policy`. Similarly, comment out the matching outputs in `terraform/environments/dev/outputs.tf`.

### Plan and Apply

```bash
terraform plan
terraform apply
```

Type `yes` when prompted. Terraform will create:

- A resource group (e.g., `rg-AzurePolicyDemo-dev-abc`)
- A NIST SP 800-53 Rev. 5 policy initiative assignment scoped to that resource group

### Verify in the Azure Portal

1. Navigate to the **Azure Portal** > **Resource Groups** and find your newly created resource group.
2. Go to **Policies** on the resource group blade.
3. You should see the **NIST SP 800-53 R5** initiative assigned.
4. Note that compliance evaluation may take up to 30 minutes for the initial scan. You can trigger an on-demand evaluation scan using:

```bash
az policy state trigger-scan --resource-group "<your-resource-group-name>"
```

---

## Step 2 — Deploy a Storage Account and Verify Compliance

Now you will deploy a storage account into the policy-governed resource group and observe how Azure Policy evaluates it against the NIST initiative.

### Uncomment the Storage Account Module

Open `terraform/project/main.tf` and uncomment the **Storage Account** module block:

```hcl
# Storage Account
module "storage_account" {
  source = "../modules/azurerm/storage_account"

  name                = replace(local.storage_account_name, "-", "")
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}
```

Also uncomment any related outputs in `terraform/project/outputs.tf` and `terraform/environments/dev/outputs.tf` that reference `module.storage_account` (if any exist).

### Plan and Apply

```bash
terraform plan
terraform apply
```

Terraform will now create a storage account inside the resource group.

### Check Compliance

1. In the **Azure Portal**, navigate to your resource group > **Policies**.
2. Wait for the compliance scan to complete (or trigger one manually):

```bash
az policy state trigger-scan --resource-group "<your-resource-group-name>"
```

3. Review the compliance results. The storage account will be evaluated against all NIST SP 800-53 Rev. 5 controls. You may see some controls flagged as **Non-compliant** — this is expected and demonstrates how Azure Policy identifies compliance gaps.
4. Click into individual policy results to understand which specific controls the storage account does or does not meet.

---

## Step 3 — Deploy a Custom Policy (Storage Account Name Length Limit)

In this step, you add a custom policy definition that **denies** the creation of storage accounts with names exceeding 10 characters. Since the existing storage account's generated name is longer than 10 characters, this demonstrates how custom policies enforce organizational naming standards.

### Uncomment the Custom Policy Module

Open `terraform/project/main.tf` and uncomment the **Custom Policy** module block:

```hcl
# Custom Policy - Storage Account Name Max Length
module "storage_name_length_policy" {
  source = "../modules/azurerm/custom_policy"

  policy_name         = "Custom-storage-name-max-length"
  policy_display_name = "Storage account name must not exceed 10 characters"
  policy_description  = "Denies creation of storage accounts whose name exceeds 10 characters."
  resource_group_id   = module.resource_group.id
  location            = var.location
  max_name_length     = 10
  resource_type       = "Microsoft.Storage/storageAccounts"
  enforcement_mode    = var.policy_enforcement_disabled
  tags                = var.tags
}
```

Also uncomment the corresponding outputs in `terraform/project/outputs.tf` and `terraform/environments/dev/outputs.tf` that reference `module.storage_name_length_policy`.

### Plan and Apply

```bash
terraform plan
terraform apply
```

This will create:

- A **custom policy definition** that checks if a storage account name exceeds 10 characters
- A **policy assignment** scoped to your resource group with a `deny` effect

### Observe the Policy in Action

1. In the **Azure Portal**, navigate to your resource group > **Policies**.
2. You should now see the custom policy **"Storage account name must not exceed 10 characters"** assigned alongside the NIST initiative.
3. Trigger a compliance scan:

```bash
az policy state trigger-scan --resource-group "<your-resource-group-name>"
```

4. The existing storage account (whose name is longer than 10 characters) will show as **Non-compliant** against this policy.
5. To test the deny effect, try creating a new storage account with a long name via the Azure Portal or CLI — the policy will block it:

```bash
az storage account create \
  --name "thisnameiswaytoolong" \
  --resource-group "<your-resource-group-name>" \
  --location "eastus" \
  --sku Standard_LRS
```

You should receive a **RequestDisallowedByPolicy** error, confirming the custom deny policy is working.

---

## Cleanup

When you are finished, destroy all resources to avoid ongoing charges:

```bash
terraform destroy
```

Type `yes` when prompted. This will remove the resource group, storage account, policy assignments, and custom policy definition.

---

## Key Takeaways

| Concept | What You Learned |
|---|---|
| **Policy Initiatives** | How to assign a built-in initiative (NIST SP 800-53 R5) to a resource group using Terraform |
| **Compliance Evaluation** | How Azure Policy evaluates deployed resources against assigned policies |
| **Custom Policies** | How to define and assign a custom policy with a `deny` effect |
| **Policy Remediation** | How non-compliant resources are flagged and how deny policies prevent future violations |
| **IaC + Policy** | How Terraform and Azure Policy work together to enforce governance as code |

---

## Troubleshooting

| Issue | Solution |
|---|---|
| `terraform init` fails | Ensure you are in the `terraform/environments/dev` directory and have internet access |
| `az login` token expired | Run `az login` again to re-authenticate |
| Compliance shows "Not started" | Trigger a manual scan with `az policy state trigger-scan` and wait a few minutes |
| Policy assignment fails with permissions error | Ensure your account has **Owner** or **Resource Policy Contributor** role on the subscription |
| Storage account name conflict | The random suffix ensures uniqueness, but if it collides, run `terraform destroy` and `terraform apply` again |
