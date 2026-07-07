# Nodefusion Auto Increment version number - backend .net core (Multiple propertyGroups)
param (
    [int]$buildNumber = $(throw "-buildNumber is required."), # the build version, from VSTS build i.e. "974"
    [string]$filePath = $(throw "-filePath is required."), #$PSScriptRoot, # path to the file i.e. 'C:\Users\ben\Code\csproj powershell\MySmallLibrary.csproj'
    [string]$type = $(throw "-type is required. |csproj|nuspec|csprojnuspec|js|ts|"), # path to the file i.e. 'C:\Users\ben\Code\csproj powershell\MySmallLibrary.nuspec'
    [bool]$exposeVSOProjectVersion = $false # exposing calculated project version to VSTS build variable ProjectVersion
)


function SetCsprojNuspecBuildVersion ([string]$currentFileType, [string]$currentFilePath)
{
    Write-Host "Starting process of generating new version number for the "$type
    Write-Host "New Build: "$buildNumber

    $xml=New-Object XML
    $xml.Load($currentFilePath)

    [string]$oldBuildString="";
	#[string]$oldAssemblyVersion="";
	#[string]$oldFileVersion="";
    $propertyToSet=-1;
    if($currentFileType -eq 'csproj')
    {
        if($xml.Project.PropertyGroup -isnot [array] -or $xml.Project.PropertyGroup.count -le 1)
        {
            $oldBuildString = $xml.Project.PropertyGroup.Version;
			#$oldAssemblyVersion = $xml.Project.PropertyGroup.AssemblyVersion;
			#$oldFileVersion = $xml.Project.PropertyGroup.FileVersion;
        }
        elseif($xml.Project.PropertyGroup.count -gt 1)
        {
            $propertyGroups = $xml.Project.PropertyGroup
            $myBuildNumber = "";
            foreach ($currentPropertyGroup in $propertyGroups)
            {
                $propertyToSet++;
	            if($currentPropertyGroup.Version)
                {
		            $oldBuildString = $currentPropertyGroup.Version;
					#$oldAssemblyVersion = $currentPropertyGroup.AssemblyVersion;
					#$oldFileVersion = $currentPropertyGroup.FileVersion;
		            break;
                }
            }
        }
        else
        {
            $(throw "Cannot find version property in csproj file: $filePath");
        }
    }
    elseif($currentFileType -eq 'nuspec')
    {
        $oldBuildString = $xml.package.metadata.version
        $propertyToSet=-2;
    }
    
    Write-Host "Current "$currentFileType" version: "$oldBuildString
    $revisionNumber = $buildNumber
	
	$oldSplitNumber = $oldBuildString.Split(".")
    $myBuildNumber = $oldSplitNumber[0] + "." + $oldSplitNumber[1] + "." + $oldSplitNumber[2] + "." + $revisionNumber
    # For Azure Universal Packages: SemVer 2.0 with prerelease suffix (e.g. 1.4.9-123)
    $myPackageVersion = $oldSplitNumber[0] + "." + $oldSplitNumber[1] + "." + $oldSplitNumber[2] + "-" + $revisionNumber
    
	#$oldAssemblyVersionSplit = $oldAssemblyVersion.Split(".")
    #$myAssemblyVersion = $oldAssemblyVersionSplit[0] + "." + $oldAssemblyVersionSplit[1] + "." + $oldAssemblyVersionSplit[2] + "." + $revisionNumber
	
	#$oldFileVersionSplit = $oldFileVersion.Split(".")
    #$myFileVersion = $oldFileVersionSplit[0] + "." + $oldFileVersionSplit[1] + "." + $oldFileVersionSplit[2] + "." + $revisionNumber
	
    #Write-Host 'Property to set: '$propertyToSet;

    if($propertyToSet -eq -2)
	{
		$xml.package.metadata.version = $myBuildNumber;
	}
    elseif($propertyToSet -eq -1)
	{
		$xml.Project.PropertyGroup.Version=$myBuildNumber;
		#$xml.Project.PropertyGroup.AssemblyVersion=$myAssemblyVersion;
		#$xml.Project.PropertyGroup.FileVersion=$myFileVersion;
	}
    else
	{
		$xml.Project.PropertyGroup[$propertyToSet].Version=$myBuildNumber;
		#$xml.Project.PropertyGroup[$propertyToSet].AssemblyVersion=$myAssemblyVersion;
		#$xml.Project.PropertyGroup[$propertyToSet].FileVersion=$myFileVersion;
	}
    $xml.Save($currentFilePath)

    Write-Host "Updated "$currentFilePath" and set build to version: "$myBuildNumber

    if($exposeVSOProjectVersion)
    {
        Write-Host "##vso[task.setvariable variable=ProjectVersion;isOutput=true]$myPackageVersion"
        Write-Host "ProjectVersion set to: $myPackageVersion"
    }
}

function SetJSTSBuildVersion ([string]$currentFileType, [string]$currentFilePath)
{
    Write-Host "Updating build version constant to "$buildNumber
    (Get-Content $currentFilePath).replace('--version--', $buildNumber) | Set-Content $currentFilePath
    Write-Host "Updated "$type" file "$currentFilePath" and set build version to "$buildNumber
}

#script execution
if($type -eq 'csprojnuspec')
{
    Write-Host "type: csprojnuspec";
    #ensuring first file is csproj
    $filePath = $filePath.replace('.nuspec','.csproj')
    SetCsprojNuspecBuildVersion 'csproj' $filePath;
    #ensuring second file is nuspec
    $secondFilePath = $filePath.replace('.csproj','.nuspec')
    SetCsprojNuspecBuildVersion 'nuspec' $secondFilePath;
}
elseif ($type -eq 'csproj' -or $type -eq 'nuspec')
{
    Write-Host "type: "$type;
    SetCsprojNuspecBuildVersion $type $filePath;
}
elseif ($type -eq 'js' -or $type -eq 'ts')
{
    Write-Host "type: "$type;
    SetJSTSBuildVersion $type $filePath;
}
else
{
    $(throw "Unknown -type parameter. |csproj|nuspec|csprojnuspec|js|ts|");
}
