# Azure Policy IaC Remediation

> **Disclaimer:** This repository — including all code, documentation, guidance, and training materials — is provided purely as a demonstration. You are free to use, modify, and adapt any of its contents as you see fit; however, everything is offered as-is with no warranty or support of any kind. Use it at your own risk. Nothing in this repository constitutes professional, legal, or compliance advice. The code is not production-ready and all content should be reviewed, understood, and adapted to suit your own environment before any real-world use.

## Overview

This repository demonstrates how to use Azure Policy, GitHub Actions, and Azure DevOps pipelines to enforce compliance and automate remediation of Infrastructure as Code. It includes Terraform configurations for deploying Azure resources with a modular architecture, plus CI/CD workflows that integrate policy validation into the deployment process.

For detailed guidance, see:
- [Governance](Governance.md) - General guidance and best practices for Azure Policy Governance.
- [Training Guide](Training.md) - Step-by-step walkthrough for learning Azure Policy with this repo


This Terraform configuration uses a three-layer modular architecture to deploy a secure Azure web application infrastructure.

## 📁 Folder Structure

```
terraform/
├── environments/
│   └── dev/
│       ├── main.tf                    # Environment-specific configuration
│       ├── variables.tf               # Environment variables
│       ├── outputs.tf                 # Environment outputs
│       └── terraform.tfvars.example   # Example configuration
├── project/
│   ├── main.tf                        # Project-level orchestration
│   ├── variables.tf                   # Project variables
│   └── outputs.tf                     # Project outputs
├── policy_content/
│   └── storage_name_max_length.tftpl  # Custom policy rule template
└── modules/
    └── azurerm/
        ├── resource_group/            # Resource Group module
        ├── storage_account/           # Storage Account module
        ├── custom_policy/             # Custom Policy Definition + Assignment
        ├── policy_assignment/         # Built-in Policy Initiative Assignment
        ├── action_group/              # Monitor Action Group (email receivers)
        ├── activity_log_alert/        # Activity Log Alert → Action Group
        ├── communication_service/     # Azure Communication Services + Email Domain
        ├── logic_app_email/           # Logic App with HTTP trigger + ACS email
        └── eventgrid_system_topic/    # Event Grid System Topic + Subscription
```

## 🏗️ Architecture Overview

### Three-Layer Design

1. **Environments Layer** (`environments/dev/`)
   - Terraform and provider version constraints
   - Generates random suffix for resource uniqueness
   - Sets environment-specific configuration
   - Calls the project module

2. **Project Layer** (`project/`)
   - Orchestrates all infrastructure components
   - Builds resource names following naming conventions
   - Calls individual resource modules
   - Manages dependencies between resources

3. **Modules Layer** (`modules/azurerm/`)
   - Reusable, single-purpose resource modules
   - Standardized inputs (name, resource_group_name, location, tags)
   - Consistent outputs (id, name, resource-specific outputs)

### Deployed Resources

- **Resource Group**: Container for all resources
- **Storage Account**: Sample resource for policy enforcement
- **Custom Policy Definition + Assignment**: Enforces storage account name max length
- **NIST SP 800-53 Rev. 5 Policy Initiative Assignment**: Built-in compliance framework
- **Action Group**: Email notification target for policy alerts
- **Activity Log Alerts**: Real-time alerts for policy audit/deny events
- **Azure Communication Services**: Email provider (ACS instance + managed domain)
- **Logic App**: Receives Event Grid events and sends email via ACS
- **Event Grid System Topic + Subscription**: Captures policy compliance state changes

## � Policy Compliance Alerting

This project implements two complementary alerting strategies to notify you via email when policies are violated or resources drift out of compliance.

### Alert Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  Real-time Policy Events (Custom Policy)                            │
│                                                                     │
│  Policy audit/deny action                                           │
│    → Activity Log Alert                                             │
│      → Action Group                                                 │
│        → Email                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  Periodic Compliance Drift (NIST SP 800-53 R5)                      │
│                                                                     │
│  Policy evaluation detects drift                                    │
│    → Event Grid (PolicyInsights.PolicyStates)                       │
│      → Logic App (HTTP trigger)                                     │
│        → ACS Email                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

### When Each Alert Type Fires

| Alert Type | Trigger | Latency | Covers |
|---|---|---|---|
| **Activity Log Alert** | A resource operation is audited or denied by a policy in real time | Seconds | Custom policies, any policy with `audit` or `deny` effect |
| **Event Grid + Logic App** | Azure Policy's periodic evaluation detects a compliance state change (created, changed, or deleted) | Minutes (depends on evaluation cycle) | Built-in initiatives like NIST SP 800-53 R5, compliance drift on existing resources |

#### Activity Log Alerts

Activity Log Alerts monitor the Azure Activity Log for specific operations and fire immediately when a matching event occurs. In the context of Azure Policy:

- **`Microsoft.Authorization/policies/audit/action`** — fires when a policy evaluates a resource and records it as non-compliant (audit effect). The resource is still created or updated, but flagged.
- **`Microsoft.Authorization/policies/deny/action`** — fires when a policy blocks a resource operation entirely (deny effect). The deployment fails.

**When to use Activity Log Alerts:**
- You want instant notification the moment a policy is triggered
- You're enforcing custom policies with `audit` or `deny` effects
- You need the simplest possible alerting setup with no intermediary services
- You want alerts on specific resource operations (create, update, delete)

**Limitations:**
- Only fires on resource operations — not during Azure Policy's background compliance evaluation scans
- Cannot detect compliance drift on resources that were deployed before the policy was assigned
- Scoped to the resource group (or subscription) defined in the alert's `scopes`

#### Event Grid + Logic App

Azure Event Grid publishes events from the `Microsoft.PolicyInsights.PolicyStates` topic type whenever Azure Policy's evaluation engine detects a compliance state change. These evaluations run periodically (typically every 24 hours for most resources, or within 30 minutes for newly assigned policies). The Event Grid subscription forwards events to a Logic App, which processes them and sends an email.

Three event types are captured:

| Event Type | When It Fires |
|---|---|
| `Microsoft.PolicyInsights.PolicyStateCreated` | A resource is evaluated for the first time and found non-compliant |
| `Microsoft.PolicyInsights.PolicyStateChanged` | A resource's compliance state transitions (e.g., compliant → non-compliant or vice versa) |
| `Microsoft.PolicyInsights.PolicyStateDeleted` | A policy assignment is removed or a resource is deleted |

**When to use Event Grid alerts:**
- You're using built-in policy initiatives (e.g., NIST SP 800-53 R5, CIS, PCI DSS) that evaluate compliance periodically
- You need to detect compliance drift on existing resources — not just new operations
- You want to be notified when a previously compliant resource becomes non-compliant (e.g., due to a configuration change outside Terraform)
- You need subscription-wide visibility into compliance state changes

**Limitations:**
- Latency depends on Azure Policy's evaluation cycle (not real-time)
- Requires intermediary processing (Logic App or Azure Function) to deliver notifications
- The Event Grid system topic is scoped to the subscription — only one `Microsoft.PolicyInsights.PolicyStates` system topic can exist per subscription

#### Combining Both

This project uses both approaches together for full coverage:

1. **Activity Log Alerts** catch policy `audit` and `deny` actions immediately as resource operations happen on custom policies
2. **Event Grid alerts** catch compliance drift detected by periodic evaluations of the NIST SP 800-53 R5 initiative

This means you're covered whether a violation happens during a deployment (Activity Log) or is discovered later during a background scan (Event Grid).

### Email Delivery Options

The alerting modules are designed to be reusable and support different email delivery mechanisms. Each has different trade-offs:

#### Action Group (Azure Monitor)

Action Groups are the native notification mechanism for Azure Monitor. They support multiple receiver types out of the box.

**How it works:** An Activity Log Alert triggers an Action Group, which sends email directly to configured receivers. No intermediary services needed.

**Capabilities:**
- Email, SMS, voice call, push notification
- Webhook, Azure Function, Logic App, ITSM, Automation Runbook
- Up to 1,000 email receivers per action group
- Built-in rate limiting (no more than 100 emails per hour per address)
- Supports Azure Resource Manager (ARM) Role-based email receivers

**Best for:** Activity Log Alerts, metric alerts, log alerts — any scenario where Azure Monitor is the alert source.

**Setup:** Fully automated via Terraform. No manual steps.

#### Azure Communication Services (ACS)

ACS provides a programmable email service with an Azure-managed domain. Emails are sent from a `DoNotReply@<id>.azurecomm.net` address.

**How it works:** A Logic App receives events via HTTP trigger, then calls the ACS Email API through a managed API connection. The connection authenticates using the ACS connection string, which Terraform provisions automatically.

**Capabilities:**
- Fully automated — no OAuth consent or manual portal steps
- Azure-managed sender domain (no DNS configuration)
- Customizable email subject, HTML body, and recipient list
- Can be reused for any Logic App workflow that needs to send email
- Supports custom domains if you want branded sender addresses (requires DNS verification)

**Best for:** Event-driven alerts via Logic App where you want zero manual setup and don't have an Office 365 license dependency.

**Setup:** Fully automated via Terraform. The `communication_service` module provisions the ACS instance, email service, managed domain, and links them together.

#### Office 365 Connector

The Office 365 connector sends email through an authenticated user's mailbox via the Microsoft Graph API.

**How it works:** A Logic App uses an Office 365 API connection (`azurerm_managed_api` with name `office365`) to send email. The connection requires a one-time OAuth authorization in the Azure portal.

**Capabilities:**
- Sends from a real user mailbox (e.g., `alerts@yourcompany.com`)
- Full Office 365 email features (importance, CC/BCC, attachments)
- Uses the familiar `Outlook` connector in Logic App designer
- Can access shared mailboxes

**Best for:** Organizations that want policy alert emails to come from a recognized internal address and already have Office 365 licensing.

**Setup:** After `terraform apply`, navigate to the API connection resource in the Azure portal → **Edit API connection** → **Authorize** → sign in → **Save**. This is a one-time step.

**To switch from ACS to Office 365:** Replace the `communication_service` and `logic_app_email` modules with an Office 365 API connection and update the Logic App action to use the `office365` connector path (`/v2/Mail`).

### Post-Deployment

After running `terraform apply`, emails will be sent to the addresses configured in `alert_email_addresses`. No additional setup is required — both the Action Group and the ACS connector are fully automated.

## �🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Active Azure subscription with appropriate permissions

### Deployment Steps

1. **Authenticate with Azure**

```bash
az login
az account set --subscription "<your-subscription-id>"
```

2. **Navigate to Environment Directory**

```bash
cd terraform/environments/dev
```

3. **Configure Variables**

Copy and customize the tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

**⚠️ IMPORTANT**: Edit `terraform.tfvars` and set secure credentials:


4. **Initialize Terraform**

```bash
terraform init
```

5. **Review the Deployment Plan**

```bash
terraform plan
```

6. **Deploy Infrastructure**

```bash
terraform apply
```

Type `yes` when prompted.


## ⚙️ Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment_prefix` | Environment name | `dev` |
| `workload` | Workload identifier | `terraform` |
| `location` | Azure region | `eastus` |
| `data_location` | Data residency region | `""` (uses location) |
| `alert_email_addresses` | List of email addresses for policy alerts | (required) |
| `policy_enforcement_disabled` | Set to `true` for audit-only mode | `false` |

### Resource Naming Convention

Resources follow: `<type>-<workload>-<environment>-<suffix>`

Examples:
- Resource Group: `rg-terraform-dev-a1b`

## 📤 Outputs

After deployment, these outputs are available:

- `resource_group_name` - Resource group name
- `resource_group_id` - Resource group ID
- `nist_policy_assignment_id` - NIST SP 800-53 R5 policy assignment ID
- `storage_name_policy_id` - Custom policy assignment ID
- `policy_alert_action_group_id` - Action group ID for email alerts
- `policy_audit_alert_id` - Activity log alert ID (audit events)
- `policy_deny_alert_id` - Activity log alert ID (deny events)
- `communication_service_id` - Azure Communication Service instance ID
- `nist_logic_app_id` - Logic App workflow ID
- `nist_eventgrid_topic_id` - Event Grid system topic ID

View all outputs:

```bash
terraform output
```

## 🔧 Module Usage

Each module follows a consistent pattern:

### Module Inputs
```hcl
module "example" {
  source = "../modules/azurerm/<resource>"
  
  name                = "resource-name"
  resource_group_name = "rg-name"
  location            = "eastus"
  tags                = { Environment = "dev" }
  
  # Resource-specific properties
}
```

### Module Outputs
```hcl
output "id" { value = azurerm_<resource>.main.id }
output "name" { value = azurerm_<resource>.main.name }
# Additional resource-specific outputs
```

## 🔄 CI/CD Pipeline Setup

Both the GitHub Actions workflow (`.github/workflows/main.yml`) and the Azure DevOps pipeline (`.ado/pipelines/main.yml`) share the same general flow:

- **CI**: Runs `fmt`, `init`, `validate`, and `plan` on pull requests targeting `main`, then posts results as a PR comment
- **CD**: Triggered manually on `main`; runs `plan`, waits for approval, then runs `apply`

### Azure Prerequisites (Required for Both)

Complete these steps once regardless of which CI/CD platform you use.

#### 1. Create a Service Principal

```bash
az ad sp create-for-rbac \
  --name "sp-terraform-cicd" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

Save the output — you will need `clientId`, `clientSecret`, `subscriptionId`, and `tenantId`.

#### 2. Create a Storage Account for Terraform State

```bash
# Create a resource group for state storage
az group create \
  --name rg-terraform-state \
  --location eastus

# Create the storage account (name must be globally unique)
az storage account create \
  --name <your-storage-account-name> \
  --resource-group rg-terraform-state \
  --sku Standard_LRS \
  --allow-blob-public-access false

# Create the state container
az storage container create \
  --name tfstate \
  --account-name <your-storage-account-name>
```

#### 3. Grant the Service Principal Access to the State Storage Account

```bash
SP_OBJECT_ID=$(az ad sp show --id <clientId> --query id -o tsv)

az role assignment create \
  --assignee-object-id $SP_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/<your-storage-account-name>
```

#### Required Secret Values

| Secret Name | Description |
|---|---|
| `ARM_CLIENT_ID` | Service principal client ID |
| `ARM_CLIENT_SECRET` | Service principal client secret |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `ARM_TENANT_ID` | Azure tenant ID |
| `TF_STATE_STORAGE_ACCOUNT` | Storage account name for Terraform state |
| `TF_STATE_RESOURCE_GROUP` | Resource group containing the state storage account |
| `DEV_LOCATION` | Azure region for the dev environment (e.g. `eastus`) |

---

### GitHub Actions Setup

#### 1. Add Repository Secrets

In your GitHub repository, go to **Settings → Secrets and variables → Actions → New repository secret** and add each value from the [Required Secret Values](#required-secret-values) table above.

#### 2. Verify the Workflow File

Ensure `.github/workflows/main.yml` exists in the repository. The workflow will activate automatically on the next pull request or push to `main`.

#### 3. Pipeline Behavior

| Trigger | Behavior |
|---|---|
| Pull request targeting `main` | Runs CI: fmt check, init, validate, plan; posts results as a PR comment |
| Manual (`workflow_dispatch`) with stage `Dev` on `main` | Runs CD: init, plan, apply to dev environment |

> The `dev` GitHub Environment can be configured under **Settings → Environments** to add required reviewers or wait timers before the deploy job runs.

---

### Azure DevOps Setup

#### 1. Install the Terraform Extension

Install the **Terraform** extension from the marketplace into your ADO organization. This provides the `TerraformInstaller@1` task used in the pipeline.

[ms-devlabs.custom-terraform-tasks](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)

#### 2. Create a Variable Group

In **Pipelines → Library → + Variable group**, create a group named `terraform-secrets` and add each value from the [Required Secret Values](#required-secret-values) table above. Mark sensitive values as secret.

#### 3. Create the Dev Environment

In **Pipelines → Environments → New environment**, create an environment named `dev`. To enforce manual approval before `apply`:

1. Open the `dev` environment
2. Select **Approvals and checks → +**
3. Add an **Approvals** check and specify the required approvers

> The `ManualValidation` task in the pipeline also adds an inline approval gate before the apply job runs, acting as a second confirmation prompt.

#### 4. Enable the Pipeline to Post PR Comments

The CI stage uses `System.AccessToken` to call the ADO REST API and post plan output as a PR comment. To enable this:

1. Edit the pipeline
2. Select **...** (more options) → **Triggers**
3. Under **YAML** → **Get sources**, check **Allow scripts to access the OAuth token**

Alternatively, add the following to the pipeline job:

```yaml
- job: TerraformPlan
  ...
  env:
    SYSTEM_ACCESSTOKEN: $(System.AccessToken)
```

This is already included in the pipeline definition.

#### 5. Create the Pipeline

1. In **Pipelines → New pipeline**, select your repository source
2. Choose **Existing Azure Pipelines YAML file**
3. Set the path to `.ado/pipelines/main.yml`
4. Link the `terraform-secrets` variable group under **Variables → Variable groups**
5. Save and run

#### 6. Pipeline Behavior

| Trigger | Behavior |
|---|---|
| Pull request targeting `main` | Runs CI stage: fmt check, init, validate, plan; posts results as a PR thread comment |
| Manual run with stage `Dev` on `main` | Runs CD stage: plan → manual approval → apply to dev environment |

---

## 🧹 Cleanup

To destroy all resources:

```bash
cd terraform/environments/dev
terraform destroy
```

Type `yes` to confirm. This will remove all resources in the resource group.

## 🐛 Troubleshooting

### Common Issues

**Terraform init fails**
- Verify Terraform version >= 1.0
- Check internet connectivity
- Clear `.terraform` directory and retry


## 📚 Additional Resources

### Terraform Providers

- [Terraform Azure Provider (azurerm)](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Azure API Provider (azapi)](https://registry.terraform.io/providers/azure/azapi/latest/docs)

### Azure Policy

- [Azure Policy Overview](https://learn.microsoft.com/en-us/azure/governance/policy/overview)
- [Azure Policy Definition Structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Azure Policy Assignment Structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/assignment-structure)
- [Azure Policy Effects (audit, deny, modify, etc.)](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects)
- [Azure Policy Compliance Evaluation](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data)
- [NIST SP 800-53 Rev. 5 Regulatory Compliance Built-in Initiative](https://learn.microsoft.com/en-us/azure/governance/policy/samples/nist-sp-800-53-r5)

### Alerting & Monitoring

- [Azure Monitor Action Groups](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups)
- [Activity Log Alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-activity-log)
- [Azure Policy Events with Event Grid](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/event-overview)
- [Azure Event Grid System Topics](https://learn.microsoft.com/en-us/azure/event-grid/system-topics)

### Azure Communication Services

- [Azure Communication Services Overview](https://learn.microsoft.com/en-us/azure/communication-services/overview)
- [ACS Email Overview](https://learn.microsoft.com/en-us/azure/communication-services/concepts/email/email-overview)
- [ACS Azure Managed Domains](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/add-azure-managed-domains)

### Logic Apps

- [Azure Logic Apps Overview](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview)
- [Logic Apps Managed Connectors](https://learn.microsoft.com/en-us/azure/connectors/managed)
