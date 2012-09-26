Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

Import-Module D:\Code\drs\psake.psm1

# Load posh-hg module from current directory
Import-Module C:\Code\posh-hg

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
# Import-Module posh-hg


# Set up a simple prompt, adding the hg prompt parts inside hg repos
function prompt {
    Write-Host($pwd) -nonewline
        
    # Mercurial Prompt
    $Global:HgStatus = Get-HgStatus
    Write-HgStatus $HgStatus
      
    return "> "
}

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)
. ./PsakeTabExpansion.ps1
Pop-Location

if(-not (Test-Path Function:\DefaultTabExpansion)) {
    Rename-Item Function:\TabExpansion DefaultTabExpansion
}

# Set up tab expansion and include hg expansion
function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1]
    
    switch -regex ($lastBlock) {
        # mercurial and tortoisehg tab expansion
        '(hg|thg) (.*)' { HgTabExpansion($lastBlock) }
        # Fall back on existing tab expansion
        default { DefaultTabExpansion $line $lastWord }
    }
}


Pop-Location

$global:psakeSwitches = '-docs', '-task', '-properties', '-parameters'

function script:psakeSwitches($filter) {
  $psakeSwitches | where { $_ -like "$filter*" }
}

function script:psakeDocs($filter) {
  psake -docs | out-string -Stream |% { if ($_ -match "^[^ ]*") { $matches[0]} } |? { $_ -ne "Name" -and $_ -ne "----" -and $_ -like "$filter*" }
}

function PsakeTabExpansion($lastBlock) {
  switch -regex ($lastBlock) {
    '(invoke-psake|psake) .* ?\-t[^ ]* (\S*)$' {
      psakeDocs $matches[2]
    }
    '(invoke-psake|psake) .* ?(\-\S*)$' {
      psakeSwitches $matches[2]
    }
    '(invoke-psake|psake) (\S*)$' {
      ls $matches[2]*.ps1 |% { "./$_" }
    }
  }
}

function hgc($comment){
    hg commit -A -m "$comment"
}

function drs {
	d:
	cd \code\drs
}

function nhs {
	c:
	cd \code\nhsbt
}

function nw {
	c:
	cd \code\nhsbt_web
}

function test{
  Invoke-psake default.ps1 Test
}

function dr{
  Invoke-psake default.ps1 dorelease
}

function acc{
  PurgeAllPrivateQueue
	Invoke-psake default.ps1 InstallAndRunAcceptansTests -properties @{ environment='FrankHome'}
}

function vc{
  PurgeAllPrivateQueue
	Invoke-psake default.ps1 VerifyCheckin -properties @{ environment='FrankHome'}
}

function Generate-Install-Dependencies{
                           $installFiles = ""
                           $nl = [Environment]::NewLine
                           $installFiles += '<?xml version="1.0" encoding="utf-8" ?>'
                           $installFiles += "$nl"
                           $installFiles += "<InstallFiles>$nl"
                           Get-ChildItem *.* -Include *.dll, *.exe, *.config | Sort-Object Name | ForEach-Object { 
                                                       $installFiles += "  <File>{0}</File>$nl" -f $_.Name
                                                       }
                           $installFiles += "</InstallFiles>"
                           Write-Output $installFiles
}

function Generate-Install-Dependencies-Test{
                           $installFiles = ""
                           $nl = [Environment]::NewLine
                           $installFiles += '<?xml version="1.0" encoding="utf-8" ?>'
                           $installFiles += "$nl"
                           $installFiles += "<InstallFiles>$nl"
                           Get-ChildItem *.* -Include *.dll, *.exe, *.config | Sort-Object Name | ForEach-Object { 
                                                       $installFiles += "  <File>{0}</File>$nl" -f $_.Name
                                                       }
                           $installFiles += "  <File>nunit.core.dll</File>$nl"
                           $installFiles += "  <File>nunit.core.interfaces.dll</File>$nl"
                           $installFiles += "  <File>nunit.util.dll</File>$nl"
                           $installFiles += "  <File>nunit-console-runner.dll</File>$nl"
                           $installFiles += "  <File>nunit-console-x86.exe</File>$nl"
                           $installFiles += "  <File>nunit-console-x86.exe.config</File>$nl"
                           $installFiles += "</InstallFiles>"
                           Write-Output $installFiles
}

function PurgeAllPrivateQueue{
  [Reflection.Assembly]::LoadWithPartialName("System.Messaging")
  $cmp = gc env:computername
  [System.Messaging.MessageQueue]::GetPrivateQueuesByMachine($cmp) | % { 
    Write-Host "Purging queue: " $_.QueueName;
    $_.Purge(); 
  }
}

function CleanBinObj{
  Get-ChildItem .\ -include bin,obj -Recurse | foreach ($_) { remove-item $_.fullname -Force -Recurse } 
}