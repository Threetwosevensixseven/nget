if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output 'Running as administrator'
} else {
    Write-Output 'Running limited'
}

function download-tool {
	Param (
		[string]$fn, 
		[string]$url = "https://github.com/Threetwosevensixseven/nget/raw/master/build/"
    )
	$force = $true;
	if ((-not $force) -and (Test-Path $fn)) {
		Write-Output "$fn already exists, not downloading"
	} else {
		Write-Output "Downloading $fn..."
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12	
		wget "$url$fn" -outfile "$fn"
		Write-Output "Downloaded $fn"
	}
}

download-tool hdfmonkey.exe
download-tool pskill.exe
download-tool ZXVersion.exe
download-tool zeustest.exe http://www.desdes.com/products/oldfiles/
