# reservation-alerts
## Purpose
Azure Automation runbook for reservation alerts.
This runbook will raise an alert to a dedicated Teams channel if a reservation usage is below a specified threshold.
All reservations in current tenant will be checked. 

## Prerequisites
### Configure Teams Channel
Reservation alerts will be sent to a Teams channel using Teams APIs.

You need to enable this feature on Channel using Incoming Webook connector see [Teams connectors [documentation](https(https://docs.microsoft.com/en-us/microsoteams/platform/webhooks-and-connectors/how-to/)add-incoming-webhook#create-an-incoming-webhook-1)

Copy generated URL to provide it as a parameter to Azure Automation runbook (will be referenced as `TeamsChannelUrl`)  

### Create and configure Azure Automation Account
Use your favorite method to create a new Azure Automation Account:
- [Azure Portal](https://docs.microsoft.com/en-us/azure/automation/automation-create-standalone-account?tabs=azureportal#create-a-new-automation-account-in-the-azure-portal) 
- [Azure CLI](https://docs.microsoft.com/fr-fr/cli/azure/automation/account?view=azure-cli-latest#az-automation-account-create)
- [Powershell](https://docs.microsoft.com/en-us/powershell/module/az.automation/new-azautomationaccount?view=azps-7.2.0)
- [Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_account) 

Sample with Powershell:
```console
New-AzAutomationAccount -Name 'myAutomationAccount' -Location 'North Europe' -ResourceGroupName 'RG-CDU'
```

### Create "Run as Account"
Run As accounts in Azure Automation provide authentication for managing resources on the Azure Resource Manager using Automation runbooks.

Follow this [documentation](https(https://docs.microsoft.com/en-us/azure/automatiocreate-run-as-account#create-account-in-azu)re-portal) to create an Automation Account using Azure Portal (easiest way) 


### Set "Run as Account" permissions
- Set global permission

By default, Run as Account Service Principal will get `Contributor` permission but we only need `Reader` permission.

These Powershell commands will remove `Contributor` and set `Reader` permissions:
```console
Remove-AzRoleAssignment -PrincipalId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx" -RoleDefinition "Contributor"

New-AzRoleAssignment -PrincipalId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx" -RoleDefinitionName "Reader"
```

*You can easily find Service Principal ID in Run as Account blade on Azure Portal*

![onfigure](images/run_as_account_spn.jpg)

 - Set reservations permission

To list all reservation on tenant, we'll use new Microsoft.Capacity scope read only permissions see [documentation](https://link)   
Pre-requisites get Reservations Reader elevated priviliege for Automation Account Managed Identity
To be run with elevated privileges See [Azure AD documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin)

```console
New-AzRoleAssignment -Scope "/providers/Microsoft.Capacity" -PrincipalId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx" -RoleDefinitionName "Reservations Reader"
```

### Configure Automation Account 



## Deploy
### Create Powershell runbook

## Test runbook

## Schedule execution

