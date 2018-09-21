# new user setup script


# get admin creds - nonadmins should never run this script
$credential = Get-Credential

# API address
$apiAddr = "https://api.samanage.com/"

# API token for Samanage admin
$samanageAuthToken = "" # get this from a config file

# get ticket number for processing
$incidentNumber = Read-Host "Please enter the new hire incident ID number, e.g. for https://help.dataxu.com/incidents/29015341-new-dataxu-fte-onboarding-form, enter 29015341"
$ticketString = $apiAddr + "incidents/" + $incidentNumber + ".xml?layout=long"

# REST headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Samanage-Authorization","Bearer $samanageAuthToken")

# gets the ticket data
$ticket = Invoke-RestMethod -Uri $ticketString -Headers $headers

# information for populating the AD user fields
$name = $ticket.incident.request_variables.request_variable[$ticket.incident.request_variables.request_variable.name.IndexOf("New Hire Name")].value
$nameSplit = $name.Split(' ')
$firstName = $nameSplit[0]
$lastName = $nameSplit[($nameSplit.Length - 1)]
$title = $ticket.incident.request_variables.request_variable[$ticket.incident.request_variables.request_variable.name.IndexOf("New Hire Title")].value
$description = $title
$manager = Get-ADUser -Filter {Name -like $ticket.incident.created_by.name}
$department = $ticket.incident.department.name
$office = $ticket.incident.site.name
$email = $firstName[0].ToString() + "$lastName" + "@dataxu.com" #first initial + last name
$email = $email.ToLower()

# need this to add correct security groups
if ($ticket.incident.name.Contains("FTE")) {
    $role = "FTE"
} elseif ($ticket.incident.name.Contains("Student")) {
    $role = "Student"
} elseif ($ticket.incident.name.Contains("Contractor")) {
    $role = "Contractor"
} else {
    $role = ""
}

# default AD security groups
if ($role -eq "Contractor" -or $role -eq "Student") {
    $defaultGroups = @("Okta-Dataxu-Contractor", "Slack-Contractor")
} else {
    $defaultGroups = @("Okta-Dataxu-FTE", "Samanage-Requester", "Dropbox-Member", "RingCentral-Standard-NoGlip", "Slack-User")
}

# temporary 10-character alphanumeric password
$password = (65..90) + (97..122) | Get-Random -Count 7 | % {[char]$_}
$password += (0..9) | Get-Random -Count 3
$password = -Join $password

# final check before writing
Write-Host "##############################"
Write-Host "The following user will be created:"
Write-Host "Name: $name"
Write-Host "Email Address: $email"
Write-Host "Title: $title"
Write-Host "Manager: $manager"
Write-Host "Department: $department"
Write-Host "Office: $office"
Write-Host "Temporary password: $password"
Write-Host "Role: $role"
Write-Host "##############################"
Write-Host ""
$ans = Read-Host "Are you sure you want to continue? Enter Y/N"


if ($ans -eq "Y" -or $ans -eq "y") {
    # connect to DX-UTILITY
    Write-Host "Connecting to DX-UTILITY."
    Enter-PSSession -ComputerName DX-UTILITY -Credential $credential

    # create the AD user
    New-ADUser -Name $name -Title $title -EmailAddress $email -Manager $manager -Office $office

    # add user to default security groups
    foreach ($group in $defaultGroups) {
        Add-ADGroupMember -Identity $group -Members $email
    }

    # directory sync to push new user info from on-prem to O365
    Start-ADSyncSyncCycle -PolicyType Initial

    } else {
        exit
    }










<#
# O365 user license
$license = if ($role -eq "Contractor" -or $role -eq "Student") {
    Set-MsolUserLicense -UserPrincipalName $email -AddLicenses "dataxu:EXCHANGEENTERPRISE"
} else {
    Set-MsolUserLicense -UserPrincipalName $email -AddLicenses "dataxu:EMS, dataxu:ENTERPRISEPACK"
}
#>