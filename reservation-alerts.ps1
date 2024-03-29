# Get Configuration Variables
$UsageThreshold = Get-AutomationVariable -Name "UsageThreshold"
$TeamsChannelUrl = Get-AutomationVariable -Name "TeamsChannelUrl"

# Connect with Run As Account Service Principal
# Will be replace by Managed Identity late around (Still in Preview)
# Connect to Azure with system-assigned managed identity
# Connect-AzAccount -Identity
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    #"Logging in to Azure..."
    Connect-AzAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantID -ApplicationId $servicePrincipalConnection.ApplicationID -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# Check SPN permissions to view Reservations at tenant level (aka Reservations Reader)
#-------------------------------------------------------------------------------------------------------------------#
# Pre-requisites get Reservations Reader elevated priviliege for Automation Account Managed Identity
# To be run with elevated privileges See https://docs.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin
#-------------------------------------------------------------------------------------------------------------------#
# New-AzRoleAssignment -Scope "/providers/Microsoft.Capacity" -PrincipalId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx" -RoleDefinitionName "Reservations Reader"
$Context = Get-AzContext
$Spn = Get-AzADServicePrincipal -ApplicationId $Context.Account.Id
$RoleAssignment = Get-AzRoleAssignment -Scope "/providers/Microsoft.Capacity" -PrincipalId $Spn.Id
if($RoleAssignment.RoleDefinitionName -ne "Reservations Reader"){
    Write-Error("Service Principal is not allowed to view reservations")
    Write-Error("Use this CmdLine to Grant Access :")
    Write-Error("New-AzRoleAssignment -Scope ""/providers/Microsoft.Capacity"" -PrincipalId SPN OBJECT ID -RoleDefinitionName ""Reservations Reader""")
}

# Get SPN Bearer Token for API calls
$AccessToken = Get-AzAccessToken -ResourceUrl "https://management.azure.com" -Tenant $servicePrincipalConnection.TenantID
$token = $AccessToken.Token

# Create empty array to store Alerts 
$Alerts = New-Object -TypeName 'System.Collections.ArrayList';

$NextLink = 'https://management.azure.com/providers/Microsoft.Capacity/reservations?api-version=2020-06-01'

while ($Null -ne $NextLink) {

    # Logs
    $NextLink

    # Get reservations for tenant
    $Reservations = (Invoke-WebRequest -UseBasicParsing -Uri $NextLink -Method GET -ContentType "application/json" -Headers @{ Authorization ="Bearer $token"}).Content

    #Convert to JSON
    $ReservationsTable = ConvertFrom-Json -InputObject $Reservations

    # Loop on reservations to check usage percentage against configured threshold
    foreach ($Reservation in $ReservationsTable.value)
    {
        #Filter when threshold > x%
        $yesterdayUsage = $Reservation.properties.utilization.aggregates[0].value
        $provisioningState = $Reservation.properties.provisioningState
        
        # Filter specific reservation tyoe if needed
        # $reservationType = $Reservation.properties.reservedResourceType
        # -and ($reservationType -ne 'Databricks')

        if(($yesterdayUsage -lt $UsageThreshold) -and ($provisioningState -eq "Succeeded"))
        {
            $Alerts.Add("<p>Alert on Reservation <b>" + $Reservation.properties.displayName + "</b> (" + $Reservation.name + ") => Yesterday Usage was " + $yesterdayUsage + "%</p>")
            $reservationType
        }
    }

    # Get next page if exists
    $NextLink = $ReservationsTable.nextLink
}

Write-Output ("Alerts = "+$Alerts)

#Publish to Teams
if($Alerts){
    $Body = @{
       'text'= $Alerts -join " "
    }

    # Build the request
    $Params = @{
            Headers = @{'accept'='application/json'}
            Body = $Body | ConvertTo-Json
            Method = 'Post'
            URI = $TeamsChannelUrl 
    }

    Invoke-RestMethod @Params
}