# Azure Policy Management with Terraform – Automated Governance Guide

## Purpose and Summary

In a cloud environment, **Azure Policy** provides the guardrails for consistent security and compliance, preventing misconfigurations and ensuring regulatory standards are met. This guide helps your team establish a **scalable, automated Azure Policy management process** using **Terraform (Infrastructure as Code)** and **CI/CD pipelines**. By treating policies as code, you gain a repeatable, version-controlled approach to governance that scales across multiple subscriptions or environments. The goal is to achieve **continuous compliance** – catching and remediating policy violations early – while clearly defining the **roles** of a central governance (security) team versus individual application or resource teams in maintaining compliance. In particular, the central governance team will define and monitor policies, while cloud platform and workload teams implement and adhere to those policies when deploying resources. <sup>[1](#ref-1)</sup>

**This guide covers:**

*   **Step-by-step instructions** to define Azure Policy as code with Terraform, enable **automatic remediation**, monitor compliance, and integrate policy checks into Azure DevOps and GitHub pipelines.
*   **Governance process** recommendations for collaboration between a central security/governance team and resource-owning teams (roles, responsibilities, workflow).
*   **Regulatory alignment** guidance for using built-in Azure Policy initiatives to meet **HIPAA/HITRUST** compliance requirements and tracking compliance status.
*   **Best practices** for policy-as-code, including use of policy initiatives, appropriate scopes, policy effects (audit, deny, deployIfNotExists), automated remediation tasks, and handling exceptions with policy exemptions.


## Governance Process & Roles

Implementing Azure Policy is not just a technical task – it requires a governance model that clearly delineates responsibilities and fosters collaboration between central and distributed teams:

*   **Central Security/Governance Team** (Cloud Governance or Cloud Center of Excellence): This team **owns the Azure Policy program**. Key duties:
    *   **Define Policies & Standards**: Determine which policies need to be in place (in line with security best practices, compliance requirements like HIPAA, and internal standards). They write or curate the policy definitions and initiatives. They also decide on policy **targets and exceptions**.
    *   **Deploy and Manage Policies**: Use Terraform (or other IaC) to implement and update the policies across the environment. They control the source repository of policies and ensure changes are reviewed.
    *   **Monitor Compliance**: Continuously monitor the compliance dashboard and Policy alerts. This team is **accountable for the overall compliance posture** of the cloud environment. They produce reports on compliance and escalate serious issues. They interface with risk management and auditors by providing evidence of controls (for example, showing that a HIPAA policy initiative is in place and tracking its compliance). <sup>[1](#ref-1)</sup>
    *   **Enforce and Educate**: When policies are violated, the central team ensures remediation occurs. They might set deadlines for fixes or even use strong measures (like modifying deployments or in extreme cases, removing non-compliant resources after due warning). They also communicate policy requirements to all teams and provide guidance (e.g., “here’s how to properly configure a storage account to meet our encryption policy”).
    *   **Maintain Governance Process**: They handle policy lifecycle – updating policies as Azure evolves, adding new policies for new threats, and refining or removing policies that are no longer needed. They also manage the **exception process** (see below).
*   **Cloud Platform Team / IT Operations**: In some organizations, there is a platform engineering team that manages the core Azure environment (landing zones, networking, shared services). This team is typically **responsible for implementing the technical mechanisms** of governance set by the central team. For example, they might set up management group hierarchies, ensure Terraform pipelines are operational, configure the CI/CD gates, and assist in deploying policies. They often work closely with the governance team to enforce policies at platform level (like ensuring new subscriptions have the standard policy assignments). <sup>[1](#ref-1)</sup>
*   **Application / Resource Owner Teams** (DevOps Teams, Project Teams): These teams own and manage individual workloads (applications, services) deployed in Azure. They are **responsible for complying** with the policies on a day-to-day basis:
    *   When designing or deploying their infrastructure as code, they must follow the rules (e.g., use approved VM images, include required tags, etc.). The CI/CD integrations and `Deny` effects on policies will help enforce this, but the mindset should be to “build compliant by design.”
    *   If a resource is flagged as non-compliant (say a VM without encryption), it’s this team’s job to take corrective action (unless an automatic remediation already fixed it). The central team will notify and track these issues, but the fix (e.g., enabling encryption or redeploying the resource correctly) is carried out by the resource owners.
    *   They provide feedback to the central team. For instance, if a policy seems to block a needed action or causes problems, they can raise these concerns so the policy can be reviewed or an exemption considered.
    *   They participate in **risk assessments** and suggest new policies or changes from their operational perspective.
*   **Collaboration Workflow**:
    1.  **Policy Rollout**: Before a new policy is enforced, the governance team might run it in audit mode and share a report of what would be non-compliant. They coordinate with resource teams on remediation of those items. Only then do they switch it to enforce (`Deny`) mode. This cooperative rollout prevents surprises and ensures buy-in.
    2.  **Non-compliance alerting**: When the governance team identifies non-compliant resources (via the dashboard or alerts), they inform the respective resource owners. This could be done through a ticket (for example, create an item in Azure DevOps or ServiceNow assigned to that team) or through direct communication. The notice should include what policy is violated, which resources, and by when it needs to be fixed.
    3.  **Remediation & Tracking**: The resource team fixes the issue (or if they need time or have constraints, they communicate that). The governance team tracks these to closure. You can maintain a simple tracker or use the Azure Policy compliance data as a live tracker.
    4.  **Policy Exceptions**: If a resource or project has a legitimate need to deviate from a policy, the resource team can request an exception. The governance team evaluates this request. If approved, an **Azure Policy exemption** is created for that specific scope or resource. For example, they might exempt a research project’s resource group from the strict location policy for 3 months because it’s testing a service only available in a particular region. All exemptions should have an **expiration or review date**. The governance team keeps a record and follows up when due, to see if the exemption can be lifted. Exemptions are a built-in mechanism in Azure Policy that prevent those resources from counting as non-compliant (so your compliance reports remain fair) while acknowledging a temporary waiver. <sup>[2](#ref-2)</sup>
    5.  **Regular Touchpoints**: Hold periodic meetings (monthly/quarterly) between the governance team and representatives of resource teams. Review compliance scores, discuss upcoming policies, share feedback from the trenches, and celebrate improvements. This keeps everyone aligned and reinforces the importance of cloud compliance as a shared goal, not a siloed responsibility.

By clearly separating **“who defines vs. who implements”**, you avoid confusion. The governance team (with leadership backing) sets the rules and monitors them; the resource teams build within those rules and fix issues when they fall short. This alignment is illustrated in Microsoft’s Cloud Adoption Framework RACI, where the governance team is *Accountable* for policies and compliance, and the platform/workload teams are *Responsible* for executing changes to meet those policies. <sup>[1](#ref-1)</sup>

## Regulatory Compliance Alignment (NIST, HIPAA/HITRUST)

If the customer operates in regulated industries or must meet federal security standards, Azure Policy can significantly aid in meeting technical compliance requirements. This section covers two commonly used frameworks — **NIST SP 800-53** and **HIPAA/HITRUST** — but the same approach applies to any built-in regulatory initiative Azure provides (CIS, PCI-DSS, ISO 27001, etc.).

### NIST SP 800-53 Rev. 5

**NIST SP 800-53** is a widely adopted security and privacy controls framework published by the National Institute of Standards and Technology. It is required for U.S. federal systems (via FedRAMP) and is frequently used as a security baseline in private-sector organizations as well.

*   **Built-in Initiative**: Azure provides a built-in **"NIST SP 800-53 Rev. 5"** policy initiative (ID: `179d1daa-458f-4e47-8086-2a68d0d6c38f`) containing hundreds of policy rules mapped to NIST control families (AC, AU, CM, IA, SC, etc.). This repo's [Training Guide](Training.md) walks through assigning this initiative at the resource group level as a hands-on exercise.
*   **Assigning with Terraform**: The approach is the same as any built-in initiative — reference the definition ID and assign it at the desired scope:
    ```hcl
    data "azurerm_policy_set_definition" "nist" {
      name = "179d1daa-458f-4e47-8086-2a68d0d6c38f"
    }
    resource "azurerm_resource_group_policy_assignment" "nist_assign" {
      name                 = "NIST-SP-800-53-R5"
      policy_definition_id = data.azurerm_policy_set_definition.nist.id
      resource_group_id    = azurerm_resource_group.example.id
      display_name         = "NIST SP 800-53 Rev. 5"
      location             = "eastus"
      identity { type = "SystemAssigned" }
    }
    ```
    For broader coverage, assign at the subscription or management group level instead.
*   **Compliance Monitoring**: Once assigned, NIST 800-53 controls appear in the Azure Policy Compliance dashboard (and in Microsoft Defender for Cloud's Regulatory Compliance view). Each control family shows which policies are passing or failing, giving you a continuous gap analysis against the framework.
*   **Relationship to Other Frameworks**: Many controls in NIST 800-53 overlap with HIPAA, HITRUST, and FedRAMP requirements. Assigning the NIST initiative alongside other regulatory initiatives gives you layered visibility — and resources that satisfy NIST controls often satisfy the corresponding HIPAA/HITRUST controls as well.

### HIPAA/HITRUST

If the customer operates in healthcare or handles protected health information, they must adhere to **HIPAA** and may pursue **HITRUST** certification. Azure Policy aids in meeting the technical portions of these standards:

*   **Built-in Compliance Initiatives**: Azure provides built-in policy **initiatives** (policy sets) for many regulatory standards. For example, there is a **“HITRUST/HIPAA”** initiative covering a broad range of controls from the HITRUST CSF (which overlaps with HIPAA requirements). This initiative contains hundreds of individual policy rules mapped to specific sections of the regulations. It includes policies to check encryption of data at rest, network security configurations, logging and monitoring settings, backup and recovery, and more – all relevant to HIPAA security rule safeguards.
*   **Assigning the Initiative**: Using Terraform, you can assign the HIPAA/HITRUST initiative to the entire subscription (or management group). The initiative’s Policy Set definition ID is static (for instance, ID `a169a624-5599-4385-a696-c8d643089fab` for HITRUST/HIPAA, version 14.x). In Terraform:
    ```hcl
    data "azurerm_policy_set_definition" "hipaa" {
      name = "a169a624-5599-4385-a696-c8d643089fab"
    }
    resource "azurerm_subscription_policy_assignment" "hipaa_assign" {
      name                 = "HIPAA-HITRUST-initiative"
      policy_definition_id = data.azurerm_policy_set_definition.hipaa.id
      subscription_id      = data.azurerm_subscription.current.id
      display_name         = "HIPAA/HITRUST Compliance"
      identity { type = "SystemAssigned" }
      # (parameters for the initiative would go here if needed)
    }
    ```
    Assign it at the highest level that makes sense (probably the production subscription or a management group encompassing all relevant resources). **Note:** Such regulatory initiatives often have many parameters. For example, you might need to specify things like which tag denotes production data, which locations are approved for data residency, etc. Providing those parameter values ensures the policy can accurately reflect compliance. Mark Tinderholt’s blog on this topic shows how to extract and provide all parameters via Terraform locals. Start with default or broad values if unsure, then refine as needed.
*   **Continuous Assessment**: Once assigned, Azure Policy will continuously evaluate all resources against the HIPAA/HITRUST controls. In the **Azure Policy Compliance** blade (or within **Microsoft Defender for Cloud’s Regulatory Compliance dashboard** if you use it), you will see a new section for HITRUST/HIPAA. It breaks down compliance by control family, showing a list of control IDs or requirement sections and an indication of compliant or not. For each control that’s failing, you can drill in to see which underlying Azure Policy caused the failure and which resources are out of compliance. This essentially provides a **real-time gap analysis** for cloud resources against HIPAA/HITRUST.
*   **Addressing Gaps**: Treat non-compliant controls surfaced by this initiative as high-priority action items. For example, if the initiative flags that “Audit logging is not enabled on XYZ service” (mapping to a HIPAA logging requirement), then enable those audits or deploy Azure Policies that configure them (some might even auto-remediate). The benefit is that Azure Policy is telling you exactly what needs to be fixed for a given control, which can save significant time in compliance audits.
*   **Scope and Limitations**: Remember that Azure Policy can only check Azure resource settings. HITRUST and HIPAA have many procedural or administrative requirements (training, physical safeguards, etc.) that Azure Policy cannot enforce. The built-in initiative addresses the technical controls (a subset of HITRUST as noted in its description). You should integrate Azure Policy’s results into your broader compliance program: use it to continuously monitor and prove technical compliance, and separately manage the non-technical compliance items.
*   **Evidence for Audits**: When audit time comes, you can export the Azure Policy compliance reports for the HIPAA initiative as evidence of control enforcement. For instance, an auditor asks, “How do you ensure all data is encrypted at rest?” – you can show the Azure Policy assignments (like “Encrypt SQL databases” policy, part of the initiative) and its compliance state (e.g., 100% of resources compliant or list of exceptions with justifications). Many organizations find that having these Azure Policy initiatives in place shortens the audit process since a lot of questions can be answered by “our Azure environment is continuously monitored against these controls, here’s the compliance dashboard output.”
*   **HITRUST Certification**: If aiming for HITRUST certification, Azure Policy won’t guarantee certification but is a powerful tool to maintain the required controls. Microsoft Azure (as a platform) is HITRUST certified, and using Azure Policy helps you inherit and enforce many of the necessary controls in your usage of Azure. Be sure to use the latest version of the HITRUST initiative, as it’s updated when controls or Azure services change (the version number in the initiative ID corresponds to the HITRUST version/update cycle).

In summary, aligning Azure Policy with standards like NIST 800-53, HIPAA, and HITRUST means you're letting Azure continuously check your cloud environment against those rigorous requirements. This reduces the chance of an overlooked security gap and provides confidence to your compliance folks. It automates a large portion of technical compliance so the team can focus on the remaining pieces.

## Terraform Azure Policy Step-by-Step Instructions

### 1. Define & Assign Azure Policies with **Terraform** (Policy as Code)

*   **Organize Policy Definitions & Initiatives**: Identify the policies your organization needs (security, operational, or compliance requirements). **Leverage Azure’s built-in policy definitions** whenever possible (for common requirements like allowed VM sizes, storage encryption, tag enforcement, etc.). For custom rules, write JSON policy **definitions** and if needed group multiple policies into a policy **initiative** (policy set) for simpler management.
    *   *Example*: Azure provides a built-in policy to **require tags** on resource groups (Policy ID: `96670d01-0a4d-4649-9c89-2d3abc0a5025`). You could include this in a broader “Resource Governance” initiative or assign it standalone.
*   **Use Terraform Resources for Policies**: Use Terraform’s AzureRM provider to manage policies as code. Key resources include:
    *   `azurerm_policy_definition` – to create a custom policy definition (or use `data.azurerm_policy_definition` for built-ins).
    *   `azurerm_policy_set_definition` – to define an initiative (a collection of policies). <sup>[3](#ref-3)</sup>
    *   `azurerm_policy_assignment` (or scope-specific variants like `azurerm_subscription_policy_assignment`, `azurerm_resource_group_policy_assignment`) – to assign a policy or initiative at a given scope. <sup>[4](#ref-4)</sup>
    *   `azurerm_policy_remediation` – to create a remediation task (discussed in the next section). <sup>[3](#ref-3)</sup>
*   **Write Terraform Configurations**: In your Terraform code, define the above resources to represent the desired state of Azure Policy:
    *   *Policy Definition Example*: Define a policy that audits untagged resource groups. Store the policy rule JSON in an external `.tftpl` template file (e.g., `policy_content/require_env_tag.tftpl`) and render it with `templatefile()`:

        **Template file** (`policy_content/require_env_tag.tftpl`):
        ```json
        {
          "if": {
            "field": "type",
            "equals": "Microsoft.Resources/subscriptions/resourceGroups"
          },
          "then": {
            "effect": "${effect}",
            "condition": {
              "field": "[concat('tags[', parameters('tagName'), ']')]",
              "exists": "false"
            }
          }
        }
        ```

        **Terraform resource**:
        ```hcl
        resource "azurerm_policy_definition" "require_tag" {
          name         = "requireEnvTag"
          policy_type  = "Custom"
          mode         = "Indexed"
          display_name = "Require Environment Tag on RGs"

          ## Use this structure with external .tftpl files for policy definitions.
          policy_rule = templatefile("${path.module}/../policy_content/require_env_tag.tftpl", {
            effect = "Audit"
          })

          parameters = jsonencode({
            tagName = {
              type = "String"
              metadata = {
                description = "Name of the required tag"
                displayName = "Tag Name"
              }
            }
          })
        }
        ```
        *(In practice, you may not need to create a custom definition if a built-in covers your requirement. The above is illustrative. Using external `.tftpl` files keeps policy rule JSON separate from Terraform HCL, making definitions easier to read, test, and reuse across modules.)*
    *   *Policy Assignment Example*: Assign the above policy at subscription scope using Terraform:
        ```hcl
        resource "azurerm_subscription_policy_assignment" "require_tag_assign" {
          name                 = "require-env-tag"
          policy_definition_id = azurerm_policy_definition.require_tag.id
          subscription_id      = data.azurerm_subscription.current.id
          display_name         = "Require Environment Tag on RGs"
          description          = "Audits resource groups missing the 'Environment' tag"
          parameters = jsonencode({
            tagName = { value = "Environment" }
          })
          identity { type = "SystemAssigned" }
        }
        ```
        This assignment will evaluate all resource groups in the subscription and mark those without the **“Environment”** tag as non-compliant. We include a **system-assigned identity** on the assignment because if in the future we add a `DeployIfNotExists` effect to auto-tag, the identity would execute that action.
*   **Apply Appropriate Scope**: Decide where to assign each policy/initiative. Many governance policies are best enforced at **management group or subscription level** (so they apply universally). Others might target specific resource groups or management groups for particular teams or environments. Terraform allows specifying the scope in the resource (as above, using `azurerm_subscription_policy_assignment` for subscription level, or using a generic `azurerm_policy_assignment` with a `scope` property). Use **exclusions** (`not_scopes` in Terraform) to exclude any child scopes that should not get the policy.
*   **Terraform Execution**: When running `terraform apply`, Terraform will create or update the policy definitions in Azure and assign them. Ensure the **Azure AD service principal or user** running Terraform has the **Resource Policy Contributor** role (or **Owner**) on the target scope. Without this, policy creation/assignment will fail with authorization errors. The Azure Policy service principal itself (for deployIfNotExists actions) will be set up via the `identity` on assignments, but your Terraform principal needs rights to create the assignment. <sup>[3](#ref-3)</sup>
*   **Source Control & Versioning**: Store all policy Terraform code in a version-controlled repository. This way, policy changes (additions, modifications, removals) go through the same review process as application code changes. You gain an audit trail of who changed what in the policies. Treat the **“policy-as-code”** repo as a living library of your cloud rules, and update it as new risks or requirements emerge.

### 2. Automate Policy Remediation (via **DeployIfNotExists/Modify** and Terraform)

*   **Use Remediation Effects in Policy Definitions**: When possible, define policies with **automatic remediation** capabilities:
    *   **deployIfNotExists**: The policy definition specifies an ARM template or artifact to deploy when a resource is missing a required component/configuration. Example: a policy that ensures VMs have the Log Analytics agent can deploy the agent extension if it’s absent.
    *   **modify**: The policy definition can directly alter certain resource properties on save. Example: a policy to add a tag or enable encryption can use a modify effect to update the resource transparently.
    *   These effects allow Azure Policy to **fix non-compliance** rather than just report it. When such a policy is assigned, any new resource will either be auto-corrected to compliance or flagged.
*   **Enable Remediation for Existing Resources**: For resources that existed before the policy assignment or that slip into non-compliance, Azure Policy supports **Remediation Tasks**. A remediation task goes through existing non-compliant resources and applies the same deploy/modify logic. You can create a remediation task in the Azure Portal (under the policy assignment’s “Remediation” tab) or automate it via Terraform:
    *   **Terraform Remediation Example**:
        ```hcl
        resource "azurerm_policy_remediation" "apply_vm_agent" {
          name                 = "remediate-vm-agents"
          policy_assignment_id = azurerm_subscription_policy_assignment.require_tag_assign.id  # ID of the assignment with deployIfNotExists
          scope                = azurerm_subscription_policy_assignment.require_tag_assign.scope  # e.g., subscription or RG scope
        }
        ```
        This triggers Azure Policy to remediate all resources under that scope that are non-compliant with the given assignment. For instance, if an initiative ensures certain security extensions on VMs, the remediation task will deploy those extensions to any VM missing them.
*   **Assign Managed Identities & Roles**: For any policy assignment that performs deployments (deployIfNotExists/modify), ensure the assignment’s **managed identity** has the necessary Azure RBAC role to make those changes. Terraform allows adding `identity { type = "SystemAssigned" }` in the policy assignment resource, which creates an identity that Azure Policy will use. You must then grant that identity appropriate rights: <sup>[3](#ref-3)</sup>
    *   If the policy deploys a resource (like enabling a monitoring agent on VMs), the identity might need Contributor on the resource’s resource group or a specific role (e.g., “Virtual Machine Contributor” to install extensions).
    *   If the policy modifies tags or other configurations, the identity needs write access to those resources.
    *   Without correct permissions, remediation tasks will fail to change the resources, so set this up at assignment time (Terraform can create a separate `azurerm_role_assignment` for the identity if needed).
*   **Verify Remediation Results**: After running Terraform (which assigns policies and possibly initiates remediation), monitor the Azure Policy **compliance state** to see if resources moved to compliant. In Azure Portal, under the policy assignment, any remediation tasks will list how many resources were successfully remediated and if any errors occurred. Make sure to address failures (it could be due to missing permissions or unsupported scenarios).
*   **Communicate to Resource Owners**: When auto-remediation is enabled, resources will change (tags added, configurations enabled) potentially without the resource owner manually intervening. Ensure your teams are aware of these changes to avoid confusion. For aspects that cannot be auto-remediated (like architectural changes), the central team should inform the resource owner team of the non-compliance so they can manually fix it. Ideally, these notifications or tasks can be automated (for example, via an ITSM tool integration or by sending an email/Teams message listing non-compliant items after each Terraform run or policy evaluation).

### 3. Monitor & Report Compliance Status

*   **Azure Policy Compliance Dashboard**: Use the **Azure Portal** to get an immediate view of compliance. Navigate to **Azure Policy > Compliance** (or **Overview**). Here you’ll see each policy assignment with its compliance percentage, number of non-compliant resources, and a trend chart of compliance over the last 7 days. You can filter by scope (e.g., a particular subscription or resource group) and drill down into each assignment to see which specific resources are not compliant. This dashboard should be your central place for tracking overall compliance posture. **Action:** Schedule a regular review (weekly or bi-weekly) of this compliance report by the governance team. <sup>[5](#ref-5)</sup>
*   **Azure Policy Insights & Logs**: Azure Policy logs all evaluation results. Consider setting up a **Log Analytics workspace** to aggregate **Policy Insights** data. This allows running queries, such as listing all current non-compliant resources across all policies, or tracking compliance trends over time. You can use **Azure Resource Graph** queries or Azure CLI (`az policy state summarize`, `az policy state list`) for on-demand snapshots. <sup>[5](#ref-5)</sup>
    *   *Tip:* Azure provides a **Policy Compliance REST API** and built-in **Azure Monitor workbook** templates for compliance. Using these, you can create custom dashboards or export compliance data for internal audits.
*   **Alerting**: For critical policies (especially security-related), set up **alerts** so that any change in compliance status triggers a notification. For example, if a resource becomes non-compliant with a high-severity policy (like “Allowed locations” or “VM open ports”), you can use an Azure Monitor Log query alert on the PolicyInsights logs to send an alert to the security team. This way, issues are caught in near-real-time, not just during periodic reviews.
*   **Reporting to Stakeholders**: Develop a concise compliance report for stakeholders (management, compliance officers). This might include:
    *   Overall compliance percentage of the environment.
    *   Key policy gaps – e.g., “10 VMs missing backup” or “5 storage accounts not encrypted” – with responsible teams identified.
    *   Trends – is compliance improving or degrading compared to last month.
    *   Status of remediation – e.g., “90% of non-compliant items auto-remediated, 3 pending manual fix.”
    *   Regulatory coverage – if using initiatives like HITRUST/HIPAA, report how many controls are passing vs failing.
    *   Use visualizations (pie charts of compliant vs non-compliant, bar charts per policy category) to make it clear. These reports can be generated automatically if you integrate Policy data with tools like Power BI or Azure Monitor Workbooks.
*   **Continuous Improvement**: Treat compliance monitoring as an iterative process:
    *   When a certain policy shows persistent non-compliance (e.g., a specific team’s resources keep violating a tag policy), engage that team to find out why. Maybe the policy needs better communication or an adjustment (or the team needs help with their deployment pipeline).
    *   Remove or update policies that are no longer relevant or that conflict with new Azure services.
    *   Use compliance data to justify improvements – e.g., if manual fixes are too frequent, consider creating a new deployIfNotExists policy to automate that scenario.

### 4. Integrate Policy Checks into **CI/CD Pipelines**

*   **Azure DevOps – Policy Compliance Gates**: Azure DevOps pipelines support an **Azure Policy compliance check gate** that can automatically evaluate policy compliance before or after a deployment:
    *   **Pre-Deployment Gates**: In a release pipeline, add a pre-deployment approval gate with the **“Check Azure Policy compliance”** task. This gate (powered by the `AzurePolicyCheckGate@0` task) will halt the pipeline and evaluate your Azure environment (at the specified scope) against all assigned policies. If any policies would be violated by the new changes, the deployment is **failed** before execution. For example, if a template tries to deploy a resource in an unauthorized region, the gate catches it. The pipeline logs will indicate which policy was violated and often include a link to details of the non-compliance. <sup>[6](#ref-6)</sup>
    *   **Post-Deployment Gates**: You can also run the compliance check after deployment (post-deployment gate) to ensure no drift or out-of-band changes made the environment non-compliant. If a violation is detected post-deployment, you might choose to roll back or create a work item for remediation.
    *   **YAML Pipelines**: In YAML, use the `AzurePolicyCheckGate@0` as well – note that it functions only as a gate (in **environment** approvals or in stages checks) and not as a regular inline task. You might define an environment in Azure DevOps representing an Azure subscription, and attach the policy check to that environment. <sup>[6](#ref-6)</sup>
    *   **Setup**: This requires an Azure service connection in DevOps with appropriate read access to Policy data (Reader or Policy Reader on the subscription should suffice). The gate configuration will ask for the scope (like /subscriptions/XYZ or a resource group ID) and a timeout. Ensure the policies are assigned and evaluated in Azure (policy assignments must exist) before this gate can enforce anything.
    *   Using these gates makes compliance **“shift-left”** – issues are caught in the pipeline, not in production. Over time, teams learn to design infrastructure changes that pass policy checks, which speeds up deployments.
*   **GitHub Actions – Policy Compliance Checks**: In GitHub, you can achieve similar compliance enforcement using Azure CLI or a provided GitHub Action:
    *   Microsoft has a [Policy Compliance Scan GitHub Action](https://github.com/Azure/azure-policy-compliance-scan) <sup>[7](#ref-7)</sup> which can trigger an on-demand evaluation of a subscription or resource group and retrieve the results. You can include this action in your workflow after a deployment step. If it finds non-compliance, you can fail the workflow or create an issue for follow-up.
    *   Alternatively, use Azure CLI in GitHub Actions: e.g., run `az policy state trigger-scan` to start a scan, then `az policy state list` or `az policy state summarize` to get results. Parse the output to decide pass/fail. There are community actions and scripts available to simplify this process. <sup>[5](#ref-5)</sup>
    *   Ensure the GitHub Action has credentials (service principal or OIDC connection) with at least **Policy Reader** permissions on the scope it’s scanning.
    *   Just like in Azure DevOps, incorporate these checks in pull request validations or deployment workflows so that any policy violations are caught early.
*   **Pipeline for Policy as Code**: Not only should you check application infrastructure, but also deploy your **policy changes** through pipelines. For example, when the governance team updates the Terraform code for a policy, use a CI pipeline to plan and apply those changes to Azure (with approvals as needed). This treats policy rollout as a formal change – reducing risk of errors and ensuring all changes are tracked.
*   **Development Team Enablement**: Make sure dev teams know these checks exist. Provide them access to run manual policy evaluations (e.g., via Azure CLI or a test pipeline) against their code changes before they push. Encourage use of tools (like **Terratest** or **Conftest with OPA**) to statically analyze Terraform for common policy violations (for instance, detect if someone is trying to open port 3389 which your policies would deny). This leads to faster development cycles with fewer pipeline failures.


## Best Practices & Key Tips

To wrap up, here are **best practices** for effective Azure Policy management with Terraform and DevOps:

*   **Treat Policies as First-Class Code**: Maintain policies in a dedicated repository, with proper version control and peer reviews for any changes. This “Policy-as-Code” approach ensures transparency and repeatability. Use meaningful naming conventions and comments in your policy definitions so others can understand what each policy does.
*   **Start with Built-in Policies**: Microsoft has a vast library of built-in policies—use them! They cover Azure Security Benchmark, CIS benchmarks, and many common scenarios. For example, rather than writing a custom policy to enforce SQL encryption, use the built-in **“Auditing on SQL server should be enabled”** or **“SQL databases should have TDE enabled”** policies. Built-ins are updated by Microsoft as Azure evolves.
*   **Use Policy Initiatives for Management**: Organize individual policies into **initiatives** (policy sets) whenever it makes sense. If you have 10 tagging policies, put them in one “Tagging Standards” initiative and assign that to all subscriptions. This reduces the number of total assignments and makes compliance reporting easier (one overall compliance score for that initiative). <sup>[1](#ref-1)</sup>
*   **Gradual Enforcement**: When introducing a new policy, consider **auditing first, then enforcing**:
    *   Assign the policy with **“Audit”** effect or **enforcementMode = Disabled** to see what would break if it were enforced. This lets teams fix issues proactively. For example, audit open RDP ports for a month and remediate VMs, then switch to deny.
    *   Use **"Deny"** effects for critical must-not-do scenarios (e.g., disallowed regions, unapproved VM instance types, public data shares) to prevent risky resources from ever being created. <sup>[4](#ref-4)</sup>
    *   Use **“DeployIfNotExists/Modify”** for things you can auto-fix (e.g., enabling diagnostics, installing extensions) – this improves compliance without burdening developers, though ensure they know something was changed on their resource.
    *   Continue using **“Audit”** for things you just want to track or where human review is needed. Auditing is also useful for soft controls or for gathering data (e.g., audit how many resources lack a certain tag).
*   **Plan for Exceptions**: Despite best efforts, there will be edge cases. Define a clear **exception process**: how can a team request an exemption, who approves it (often the security governance lead or a risk management function), and for how long. Use Azure Policy **Exemptions** to implement approved exceptions in a way that’s tracked by the platform. Avoid the temptation to just tell the team “ignore that policy for now” – formalize it via an exemption so it’s visible and has an expiration. <sup>[2](#ref-2)</sup>
*   **Regularly Update and Cleanup**: Revisit your policies periodically. Azure might release improved versions of built-ins or entirely new policy capabilities (like container policies, Kubernetes policies, etc.). Update your definitions to leverage these. Also, remove any redundant or overly legacy policies to keep the set focused and efficient (e.g., if all resources are now using managed identities by default, you might retire a policy that enforced a workaround).
*   **Performance Considerations**: Having hundreds of policy assignments can slightly impact deployment times (as Azure must check them) and certainly creates noise to manage. That’s another reason to use initiatives and to scope policies thoughtfully. Also, avoid overly complex policy rules with heavy logic if possible, as they may be harder to evaluate and maintain. Typically, the default evaluations (once every 24 hours and on resource changes) are sufficient – but if you need to force an on-demand scan, know that it can take time for large environments. <sup>[5](#ref-5)</sup>
*   **CI/CD Integration**: Make Azure Policy a non-optional part of your release process. If a build or release is blocked by a policy gate, do **not** simply bypass it – use that as a teaching moment and require the team to address the issue or get a formal exemption. The integrity of your governance depends on consistently enforcing these checks.
*   **Documentation and Training**: Document each policy in a human-readable way (what it does, why it exists, how to remediate a violation). Publish this internally so teams can self-service (“My deployment failed due to a policy – let me look up what that policy means.”). Provide training or office hours for development teams on Azure Policy and Terraform basics, so they understand how to comply and even contribute suggestions.
*   **Leverage Community and Tools**: Microsoft’s **Enterprise Policy As Code (EPAC)** project and Azure Landing Zone samples provide predefined sets of policies as code, pipeline configurations, and scripts. These can serve as reference implementations or even be adapted directly. If you haven’t already, explore those resources to accelerate your setup.
*   **Security & Least Privilege**: Limit who can alter policies. Only the central governance team (and perhaps cloud admins) should have write access to policy assignments. This prevents someone from loosening a policy to get their deployment through without proper approval. Use Azure Role-Based Access Control (RBAC) accordingly – e.g., developers might have Owner on their resource group but not Policy Contributor, so they can’t exempt themselves or change assignments.

By following these best practices, your Azure environment will have a robust governance foundation: policies defined as code, automatically enforced and remediated, integrated into development workflows, and supported by clear processes for collaboration and improvement. This means fewer security incidents, easier audits, and more confidence as you and your customer adopt Azure at scale.

***

## Summary of Key Steps & Responsibilities

The table below summarizes the key steps in managing Azure Policy with Terraform, who is primarily responsible for each, and the tools or methods used:

| **Step / Function**                                 | **Primary Responsibility**                                                                                                                                         | **How to Execute (Tools & Methods)**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Define Policy & Initiatives (Policy-as-Code)** | **Security/Governance Team** – defines requirements and writes policies (consulting architects/compliance as needed).                                              | – Terraform with AzureRM: Write `azurerm_policy_definition` and `azurerm_policy_set_definition` for custom policies/initiatives <sup>[3](#ref-3)</sup>.<br>– Use Microsoft **built-in policies** from Azure Policy library for standard controls (no-code or use Terraform data sources to reference them).                                                                                                                                                                                                                                                                                                                                               |
| **2. Assign Policies via Terraform**                | **Security/Governance Team** – deploys policy assignments; <br>**Cloud Platform/Ops Team** – assists if needed with environment access or pipeline setup.          | – Terraform: Use `azurerm_policy_assignment` resources to assign at management group, subscription, or resource group scopes <sup>[4](#ref-4)</sup>.<br>– **Scope**: Assign broad policies at high level (e.g., management group) with `not_scopes` for exceptions.<br>– **Permissions**: Ensure Terraform’s credentials have **Resource Policy Contributor** or Owner on target scope <sup>[3](#ref-3)</sup>.                                                                                                                                                                                                                                                                |
| **3. Automate Remediation**                         | **Security/Governance Team** – configures remediation in policy definitions; triggers tasks;<br>**Resource Teams** – review changes applied to their resources.    | – **Policy Definition**: include `deployIfNotExists` or `modify` effects in policy rule for auto-remediation.<br>– **Terraform**: after assignment, create `azurerm_policy_remediation` to run the remediation task.<br>– **Azure Portal/CLI**: Monitor remediation task status and logs (Policy Compliance blade or `az policy remediation` commands).<br>– **Managed Identity**: Set assignment identity and grant needed roles (e.g., VM Contributor for VM extensions) <sup>[3](#ref-3)</sup>.                                                                                                                                   |
| **4. Monitor Compliance Continuously**              | **Security/Governance Team** – monitors overall compliance and reports;<br>**Resource Teams** – fix non-compliance on their resources.                             | – **Azure Portal**: Azure Policy **Compliance** dashboard for summary and per-policy details <sup>[5](#ref-5)</sup>.<br>– **Azure Monitor/Resource Graph**: Query policy states for custom reports or alerts <sup>[5](#ref-5)</sup>.<br>– **Alerts**: Set up Azure Monitor alerts for critical policy breaches (e.g., email or Teams notification).<br>– **Reporting**: Monthly compliance report to stakeholders, highlighting key metrics and remediation progress.                                                                                                               |
| **5. Enforce in CI/CD Pipelines**                   | **DevOps/Platform Team** – implements pipeline checks;<br>**Security Team** – defines policy gate criteria and oversees enforcement.                               | – **Azure DevOps**: Add **AzurePolicyCheckGate@0** as a pre-deployment gate in release pipelines <sup>[6](#ref-6)</sup> (or use environment approvals in YAML). Fails pipeline on policy violations.<br>– **GitHub Actions**: Use Azure CLI or Azure Policy Compliance Scan action to evaluate compliance after deployment <sup>[5](#ref-5)</sup>. Fail or create issues based on results.<br>– **Infrastructure Pipelines**: Integrate policy code deployment into pipelines (e.g., automatically apply Terraform for policies on merge). |
| **6. Govern & Update Policies**                     | **Security/Governance Team** – maintains policy lifecycle; <br>**Executive Sponsor** – supports and communicates importance; <br>**All Teams** – provide feedback. | – **Policy Reviews**: Periodically assess if policies meet current needs; update Terraform code to add/remove or tweak definitions (with approvals).<br>– **Exemptions**: Use `azurerm_policy_exemption` (or Azure Portal) to record approved exceptions with expiration <sup>[2](#ref-2)</sup>.<br>– **Communication**: Announce new/updated policies and their impact. Provide guidelines or training as needed so teams can comply.                                                                                                                                                                                                                                                                                                                                                                     |

By following these steps and responsibilities, the customer’s organization will establish a robust Azure Policy management practice. This ensures that as they deploy resources with Terraform, all deployments are continuously guarded by Azure Policy – resulting in an Azure environment that is secure, compliant with standards like HITRUST/HIPAA, and governed by clear processes rather than ad-hoc checks.
## References

1. <a id="ref-1"></a>[Cloud Adoption Framework – Build Cloud Governance Team](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/govern/build-cloud-governance-team)
2. <a id="ref-2"></a>[Azure Policy Exemption Structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/exemption-structure)
3. <a id="ref-3"></a>[Implementing Azure Policy Using Terraform](https://techcommunity.microsoft.com/blog/azurepaasblog/implementing-azure-policy-using-terraform/1423775)
4. <a id="ref-4"></a>[Assign Azure Policy with Terraform](https://learn.microsoft.com/en-us/azure/governance/policy/assign-policy-terraform)
5. <a id="ref-5"></a>[Get Azure Policy Compliance Data](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data)
6. <a id="ref-6"></a>[Azure Policy DevOps Pipelines Tutorial](https://learn.microsoft.com/en-us/azure/governance/policy/tutorials/policy-devops-pipelines)
7. <a id="ref-7"></a>[Azure Policy Compliance Scan GitHub Action](https://github.com/Azure/policy-compliance-scan)
