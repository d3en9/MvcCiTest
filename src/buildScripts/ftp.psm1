[string]$script:ftpHost
[System.Net.WebClient]$script:webClient = New-Object System.Net.WebClient

function Set-FtpConnection {
    param([string]$host, 
          [string]$username, 
          [string]$password)
    
    $script:ftpHost = $host
    $script:webClient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
}

function Send-ToFtp {
    param([string]$sourcePath)
    
    write-host $sourcePath
    write-host $script:ftpHost
}

Export-ModuleMember Set-FtpConnection, Send-ToFtp