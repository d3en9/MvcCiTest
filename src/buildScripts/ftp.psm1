[string]$script:ftpHost
[string]$script:username
[string]$script:password
[System.Net.NetworkCredential]$script:Credential

function Set-FtpConnection {
    param([string]$host, 
          [string]$username, 
          [string]$password)
    
    $script:Credential = New-Object System.Net.NetworkCredential($username, $password) 
	$script:ftpHost  = $host
	$script:username = $username
	$script:password = $password
	
}

function Send-ToFtp {
    param([string]$sourcePath,
		  [string]$ftpFolder)

    foreach($item in Get-ChildItem -recurse $sourcePath){ 
		$itemName = [System.IO.Path]::GetFullPath($item.FullName).SubString([System.IO.Path]::GetFullPath($sourcePath).Length + 1)
		$fullFtpPath = [System.IO.Path]::Combine($script:ftpHost+"/$ftpFolder/", $itemName)
        if ($item.Attributes -eq "Directory"){
            try{
				$uri = New-Object System.Uri($fullFtpPath)
                $fullFtpPathRequest = [System.Net.WebRequest]::Create($uri)
                $fullFtpPathRequest.Credentials = $script:Credential
                $fullFtpPathRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
                $fullFtpPathRequest.GetResponse()
            }catch [Net.WebException] {
                Write-Host "$item probably exists ..."
            }
            continue;
        }
		
		$webClient = New-Object System.Net.WebClient
		$webClient.Credentials = $script:Credential
		$uri = New-Object System.Uri($fullFtpPath)
        $webClient.UploadFile($uri, $item.FullName)
    }
}

function Get-FromFtp($sourceFolder, $ftpFolder) {

	$fullFtpPath = [System.IO.Path]::Combine($script:ftpHost, $ftpFolder)
    $dirs = Get-FtpDirecoryTree $fullFtpPath
	
	#$dirs | Write-Host
	
    <#foreach($dir in $dirs){
       $path = [io.path]::Combine($sourceDestination, $dir)
       
       if ((Test-Path $path) -eq $false) {
          "Creating $path ..."
		  New-Item -Path $path -ItemType Directory | Out-Null
	   }else{
          "Exists $path ..."
       }
    }
    
    $files = Get-FilesTree $fullFtpPathUri
    foreach($file in $files){
        $source = [io.path]::Combine($fullFtpPathUri, $file)
        $dest = [io.path]::Combine($destination, $file)
        "Downloading $source ..."
        Get-FtpFile $source $dest $user $pass
    }#>
}

function Get-FtpDirecoryTree($fullFtpPath) {    
	if($fullFtpPath.EndsWith("/") -eq $false) {
		$fullFtpPath = $fullFtpPath += "/"
	}
	
	$folderTree = New-Object "System.Collections.Generic.List[string]"
    $folders = New-Object "System.Collections.Generic.Queue[string]"
    $folders.Enqueue($fullFtpPath)
    while($folders.Count -gt 0) {
        $folder = $folders.Dequeue()
		Write-Host "getting content from $folder"
        $directoryContent = Get-FtpDirectoryContent $folder
        $dirs = Get-FtpDirectories $folder
        
        foreach ($line in $dirs){
            $dir = @($directoryContent | Where { $line.EndsWith($_) })[0]
            $directoryContent.Remove($dir)
			
			$enq = $folder + $dir + "/"
			Write-Host "adding $enq"
            $folders.Enqueue($enq)
            $folderTree.Add($folder.Replace($fullFtpPath, "") + $dir + "/")
        }
    }
    return ,$files
}

function Get-FtpDirectories($folder) {
    $dirs = New-Object "system.collections.generic.list[string]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $reader = Get-Stream $folder $operation
    while (($line = $reader.ReadLine()) -ne $null) {
       
       if ($line.Trim().ToLower().StartsWith("d") -or $line.Contains(" <DIR> ")) {
            [void]$dirs.Add($line)
        }
    }
    $reader.Dispose();
    
    return ,$dirs
}

function Get-FtpDirectoryContent($folder) {
    $files = New-Object "System.Collections.Generic.List[String]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        
    $reader = Get-Stream $folder $operation
    
    while (($line = $reader.ReadLine()) -ne $null) {
       [void]$files.Add($line.Trim()) 
    }
    $reader.Dispose();
    
    return ,$files
}

function Get-Stream($url, $meth) {
    $fullFtpPath = [System.Net.WebRequest]::Create($url)
    $fullFtpPath.Credentials = $script:Credential
    $fullFtpPath.Method = $meth
    $response = $fullFtpPath.GetResponse()
    
    return New-Object IO.StreamReader $response.GetResponseStream()
}

Export-ModuleMember Set-FtpConnection, Send-ToFtp, Get-FromFtp