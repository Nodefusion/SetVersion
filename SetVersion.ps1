# SetVersion script for updating project build versions

# all parameters are required
# -buildNumber - the number which will be set as a build number in your version, i.e. 13
# -filePath - path to the file in which we want to change the build version
# -type - type of the file which will be changed
param (
    [int]$buildNumber = $(throw "-buildNumber is required."), # the build version, from VSTS build i.e. "974"
    [string]$filePath = $(throw "-filePath is required."), #$PSScriptRoot, # path to the file i.e. 'C:\Users\ben\Code\csproj powershell\MySmallLibrary.csproj'
    [string]$type = $(throw "-type is required. |csproj|nuspec|csprojnuspec|js|ts|") # path to the file i.e. 'C:\Users\ben\Code\csproj powershell\MySmallLibrary.nuspec'
)

# function which works with both nuspec and csproj files, reads the current version from the file and then replaces only 
# the part of the version (revisionNumber) with the -buildNumber you've specified
function SetCsprojNuspecBuildVersion ([string]$currentFileType, [string]$currentFilePath)
{
    Write-Host "Starting process of generating new version number for the "$type
    Write-Host "New Build: "$buildNumber
    $xml=New-Object XML
    $xml.Load($currentFilePath)

    [string]$oldBuildString="";
    # propertyToSet is a switch/indexer (depending on a type of csproj) for the property which has to be replaced
    $propertyToSet=-1; # csproj - only one Property group element in csproj so version property path is defined
    if($currentFileType -eq 'csproj')
    {
        if($xml.Project.PropertyGroup -isnot [array] -or $xml.Project.PropertyGroup.count -le 1)
        {
            $oldBuildString = $xml.Project.PropertyGroup.Version
        }
        elseif($xml.Project.PropertyGroup.count -gt 1)
        {
            $propertyGroups = $xml.Project.PropertyGroup
            $myBuildNumber = "";
            foreach ($currentPropertyGroup in $propertyGroups)
            {
                $propertyToSet++; # csproj - multiple Property group elements in csproj so version property path is dynamic and the variable is incremented to point to correct index
	            if($currentPropertyGroup.Version)
                {
		            $oldBuildString = $currentPropertyGroup.Version;
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
        $propertyToSet=-2; # nuspec - defined version property path
    }
    
    Write-Host "Current "$currentFileType" version: "$oldBuildString
    # split the current version to subnumbers
    $oldSplitNumber = $oldBuildString.Split(".")
    # define the new version subnumber properties
    $majorNumber = $oldSplitNumber[0]
    $minorNumber = $oldSplitNumber[1]
    $maintenanceNumber = $oldSplitNumber[2]
    $revisionNumber = $buildNumber
    # define the new version
    $myBuildNumber = $majorNumber + "." + $minorNumber + "." + $maintenanceNumber + "." + $revisionNumber
    
    # set the new version property
    # nuspec
    if($propertyToSet -eq -2)
        {$xml.package.metadata.version = $myBuildNumber;}
    # csproj - one PropertyGroup element
    elseif($propertyToSet -eq -1)
        {$xml.Project.PropertyGroup.Version=$myBuildNumber;}
    # csproj - multiple PropertyGroup elements
    else
        {$xml.Project.PropertyGroup[$propertyToSet].Version=$myBuildNumber;}
    # save the xml file
    $xml.Save($currentFilePath)

    Write-Host "Updated "$currentFilePath" and set build to version: "$myBuildNumber
}

# function which works best for frontend projects where you actually can replace some placeholder text into the build number
# placeholder text which your file should contain is: '--version--' (without quotes)
function SetJSTSBuildVersion ([string]$currentFileType, [string]$currentFilePath)
{
    Write-Host "Updating build version constant to "$buildNumber
    (Get-Content $currentFilePath).replace('--version--', $buildNumber) | Set-Content $currentFilePath
    Write-Host "Updated "$type" file "$currentFilePath" and set build version to "$buildNumber
}

#script logic execution
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
