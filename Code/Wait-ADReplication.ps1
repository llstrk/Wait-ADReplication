function Wait-ADReplication {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ParameterSetName="UPN")]
        [string]$UPN,

        [Parameter(Mandatory, ParameterSetName="DistinguishedName")]
        [string]$DistinguishedName,

        [Parameter(Mandatory, ParameterSetName="SAMAccountName")]
        [string]$SAMAccountName,

        [Parameter(Mandatory, ParameterSetName="GPOGuid")]
        [string]$GPOGuid,

        [Parameter(Mandatory)]
        [string]$DomainName
    )

    $dcs = Get-ADDomainController -Server $DomainName -Filter '*' -ErrorAction 'Stop'

    foreach ($dc in $dcs) {
        $adobjectFound = $false

        $startTime = [DateTime]::Now
        Write-Verbose "Waiting for AD replication on $($dc.Hostname)..."
        for ($i = 0; $i -lt 90; $i++) {
            $adobject = $null
            if ($UPN) {
                if ($i -eq 0) {
                    Write-Verbose "UPN to find: $UPN"
                }
                $adobject = Get-ADObject -Server $dc.HostName -LDAPFilter "(userPrincipalName=$UPN)"
            }
            elseif ($DistinguishedName) {
                if ($i -eq 0) {
                    Write-Verbose "DistinguishedName to find: $DistinguishedName"
                }
                $adobject = Get-ADObject -Server $dc.HostName -LDAPFilter "(distinguishedName=$DistinguishedName)"
            }
            elseif ($GPOGuid) {
                if ($i -eq 0) {
                    Write-Verbose "GPOGuid to find: $GPOGuid"
                }
                $adobject = Get-ADObject -Server $dc.HostName -LDAPFilter "(name={$GPOGuid})"
            }
            else {
                if ($i -eq 0) {
                    Write-Verbose "SAMAccountName to find: $SAMAccountName"
                }
                $adobject = Get-ADObject -Server $dc.HostName -LDAPFilter "(sAMAccountName=$SAMAccountName)"
            }

            if ($adobject -ne $null) {
                Write-Verbose ("Object found on $($dc.Hostname). Replication took {0:N0} seconds." -f ([DateTime]::Now - $startTime).TotalSeconds)
                $adobjectFound = $true
                break
            }
            else {
                if ( $i -gt 0 -and ($i % 10) -eq 0) {
                    Write-Verbose ("Object not found yet. Waited for {0:N0} seconds..." -f ([DateTime]::Now - $startTime).TotalSeconds)
                }
                sleep 1
            }
        }

        if (-not $adobjectFound) {
            Write-Error "Object was never found on $($dc.HostName)" -ErrorAction 'Stop'
        }
    }
}