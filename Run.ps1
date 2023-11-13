[System.Collections.ArrayList]$DataCollector = @()
$SearchPath = "OU=Servers,DC=DOMAIN,DC=com"
# WARNING : Due to a known bug in certain windows OS versions searching for the Administrator group fails.
$GroupName = "Remote Desktop Users"
$IgnoreList = Get-Content -Path "./IgnoreList.txt"

Try{Remove-Item -Path ./ADGroupReport.csv|Out-Null}Catch{Write-Host "File Already Removed"}
$ComputersList = Get-ADComputer -filter "Enabled -eq 'True'" -SearchBase $SearchPath

for($idx = 0; $idx -lt $($($ComputersList).count); $idx++ ) {
    Write-Host "$($ComputersList.Count)"
    If(-not($IgnoreList -contains $($ComputersList[$idx].Name))){
        Try{
        $GroupContents = Invoke-Command -ComputerName $($ComputersList[$idx].Name) -ScriptBlock{Get-LocalGroupMember -Group "Remote Desktop Users"}
        }catch{Write-Host "Cannot Complete Command: $_"}
        $GroupContents

        Foreach ($User in $GroupContents) {
            $User

            $ValueCollector = [pscustomobject]@{'Name' = ($ComputersList[$idx].Name); 'Group' = ($GroupName);`
            'GroupContents' = ($User.Name); 'ObjectClass' = ($User.ObjectClass); 'Alert' = ("TEMP")}

            # $ValueCollector
            $DataCollector.add($ValueCollector)
        }
        If($null -eq $GroupContents){
            $ValueCollector = [pscustomobject]@{'Name' = ($ComputersList[$idx].Name); 'Group' = ($GroupName);`
            'GroupContents' = ("Null"); 'ObjectClass' = ("Null"); 'Alert' = ("PC has no Accounts in Group")}
            $DataCollector.add($ValueCollector)
        }
    }Else{
        Write-Host "$($ComputersList[$idx].Name) is on the do not search list." -BackgroundColor Red
        $ValueCollector = [pscustomobject]@{'Name' = ($ComputersList[$idx].Name); 'Group' = ($GroupName);`
        'GroupContents' = ("Null"); 'ObjectClass' = ("Null"); 'Alert' = ("PC is on Ignore List")}
        $DataCollector.add($ValueCollector)
    }
}

Write-Host "Script Exit"
$DataCollector | export-csv -Path ./ADGroupReport.csv