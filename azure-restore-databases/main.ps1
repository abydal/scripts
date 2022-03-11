$resourceGroup = "Default-SQL-WestEurope"
$sqlPassword = "<sql-server-password>" 

$databases = Import-Csv -Path .\Azureresources.csv | Where-Object Type -like "SQL database" | Where-Object Name -like "customer_*"

$totalCount = $databases.Count
Write-Host "Running script on $totalCount databases"

$databases | ForEach-Object -ThrottleLimit 20 -Parallel {
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    
    if (Test-Path -Path ".stop" -PathType Leaf) {
        Write-Host "Found .stop - stopping"
        break;
    }

    function Export-Sql { 
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$query,
            [Parameter(Mandatory)]
            [string]$path,
            [Parameter(Mandatory)]
            [System.Data.SQLClient.SQLConnection]$connection
        )
        try {
            $command = $connection.CreateCommand()
            $command.CommandText = $query
            $Datatable = New-Object "System.Data.Datatable"
            $result = $command.ExecuteReader()
            $Datatable.Load($result)
            $Result = $Datatable
            if ($Result.Rows.Count -gt 0) {
                $Result | Export-Csv $path
            }
        }
        catch {
            Write-Output "Could not export query $query to file $path"
            Write-Output $_
        }
    }

    $splitString = -split $_.Name
    $serverName = ($splitString[1] -split "/")[0].Trim("(")
    $databaseName = ($splitString[1] -split "/")[1].Trim(")")
    
    $restoredDatabase = Get-AzSqlDatabase -ResourceGroupName $using:resourceGroup -ServerName $serverName -DatabaseName "$databaseName-restored" -ErrorAction:SilentlyContinue
    
    if($restoredDatabase -eq $null) {
        try {
            $restorePoint = Get-Date -Year 2022 -Month 2 -Day 12
            $database = Get-AzSqlDatabase -ResourceGroupName $using:resourceGroup -ServerName $serverName -DatabaseName "$databaseName"
            
            Write-Host "Restoring $databaseName on server $serverName"
            Restore-AzSqlDatabase -FromPointInTimeBackup -PointInTime $restorePoint -ResourceGroupName $database.ResourceGroupName -ServerName $database.ServerName -TargetDatabaseName "$databaseName-restored" -ResourceId $database.ResourceID -Edition "Standard" -ServiceObjectiveName "S2"
        }
        catch {
            Write-Output "Could not restore database $databaseName on server $serverName - exiting"
            exit
        }
    }
    else {
        Write-Output "Database $databaseName is already restored"
    }
    
    New-Item -Name $databaseName -ItemType "directory" -ErrorAction:SilentlyContinue
    
    $ticketTemplateQuery = "SELECT * from [TicketTemplates]"
    $changeTemplateQuery = "SELECT * from [ChangeTemplates]"
    
    $ticketTemplateAttachmentsQuery = "SELECT *
    FROM [dbo].[TicketTemplateAttachments] tta 
    join Attachments a on a.Id = tta.AttachmentId
    join AttachmentContents ac on ac.ContentId = a.ContentId" 
    
    $changeTemplateAttachmentsQuery = "SELECT *
    FROM [dbo].[ChangeTemplateAttachments] tta 
    join Attachments a on a.Id = tta.AttachmentId
    join AttachmentContents ac on ac.ContentId = a.ContentId" 
    
    $ticketTemplateTaskQuery = "select * from TaskTemplateTasks where TicketTemplateId is not null"
    $changeTemplateTaskQuery = "select * from TaskTemplateTasks where ChangeTemplateId is not null"
    
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$serverName.database.windows.net';database='$databaseName-restored';Password='$using:sqlPassword';User ID='pureservice@$serverName'"
    
    $Connection.Open()
    Write-Output "Executing sql querys on database $databaseName-restored" 
    Export-Sql -query $ticketTemplateQuery -path "$databaseName/TicketTemplates.csv" -connection $Connection 
    Export-Sql -query $changeTemplateQuery -path "$databaseName/ChangeTemplates.csv" -connection $Connection 
    Export-Sql -query $ticketTemplateAttachmentsQuery -path "$databaseName/TicketTemplateAttachments.csv" -connection $Connection 
    Export-Sql -query $changeTemplateAttachmentsQuery -path "$databaseName/ChangeTemplateAttachments.csv" -connection $Connection 
    Export-Sql -query $ticketTemplateTaskQuery -path "$databaseName/TicketTemplateTasks.csv" -connection $Connection 
    Export-Sql -query $changeTemplateTaskQuery -path "$databaseName/ChangeTemplateTasks.csv" -connection $Connection 
    
    $Connection.Close()
    
    Remove-AzSqlDatabase -ResourceGroupName $using:resourceGroup -ServerName $serverName -DatabaseName "$databaseName-restored"
}
