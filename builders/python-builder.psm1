class PythonBuilder {
    <#
    .SYNOPSIS
    Base Python builder class.

    .DESCRIPTION
    Base Python builder class that contains general builder methods.

    .PARAMETER Version
    The version of Python that should be built.

    .PARAMETER Architecture
    The architecture with which Python should be built.

    .PARAMETER HostedToolcacheLocation
    The location of hostedtoolcache artifacts. Using system AGENT_TOOLSDIRECTORY variable value.

    .PARAMETER TempFolderLocation
    The location of temporary files that will be used during Python generation. Using system TEMP directory.

    .PARAMETER WorkFolderLocation
    The location of generated Python artifact. Using system environment BUILD_STAGINGDIRECTORY variable value.

    .PARAMETER ArtifactFolderLocation
    The location of generated Python artifact. Using system environment BUILD_BINARIESDIRECTORY variable value.

    .PARAMETER InstallationTemplatesLocation
    The location of installation script template. Using "installers" folder from current repository.

    #>

    [semver] $Version
    [string] $Architecture
    [string] $Platform
    [string] $HostedToolcacheLocation
    [string] $TempFolderLocation
    [string] $WorkFolderLocation
    [string] $ArtifactFolderLocation
    [string] $InstallationTemplatesLocation
    [string] $ConfigsLocation

    PythonBuilder ([string] $version, [string] $architecture, [string] $platform) {
        $this.InstallationTemplatesLocation = Join-Path -Path $PSScriptRoot -ChildPath "../installers"
        $this.ConfigsLocation = Join-Path -Path $PSScriptRoot -ChildPath "../config"

        $this.HostedToolcacheLocation = $env:AGENT_TOOLSDIRECTORY
        $this.TempFolderLocation = $env:BUILD_SOURCESDIRECTORY
        $this.WorkFolderLocation = $env:BUILD_BINARIESDIRECTORY
        $this.ArtifactFolderLocation = $env:BUILD_STAGINGDIRECTORY

        $this.Version = $this.ConvertVersion($version, "PythonNotation")
        $this.Architecture = $architecture
        $this.Platform = $platform
    }

    [uri] GetBaseUri() {
        <#
        .SYNOPSIS
        Return base URI for Python build sources.
        #>

        return "https://www.python.org/ftp/python"
    }

    [string] GetPythonToolcacheLocation() {
        <#
        .SYNOPSIS
        Return path to Python hostedtoolcache folder.
        #>

        return "$($this.HostedToolcacheLocation)/Python"
    }

    [string] GetFullPythonToolcacheLocation() {
        <#
        .SYNOPSIS
        Return full path to hostedtoolcache Python folder.
        #>

        $pythonToolcacheLocation = $this.GetPythonToolcacheLocation()
        return "$pythonToolcacheLocation/$($this.Version)/$($this.Architecture)"
    }

    [string] GetVersion() {
        <#
        .SYNOPSIS
        Return Major.Minor.Build version string.
        #>

        return "$($this.Version.Major).$($this.Version.Minor).$($this.Version.Patch)"
    }

    [string] ConvertVersion($version, $notation) {
        <#
        .SYNOPSIS
        Convert version to required notation correct

        .PARAMETER Version
        The version of Python that should be converted.

        .PARAMETER notation
        The notation that should be used in version. Described in versions-mapping.json config file.

        #>

        # Load version mapping
        $versionMap = $this.GetVersionMapping()
        $mapContext = $versionMap | Select-Object -ExpandProperty $notation

        # Get required delimiters and regexp pattern
        $preReleaseDelimiter = $mapContext | Select-Object -ExpandProperty "preReleaseDelimiter"
        $releseVersionDelimiter = $mapContext | Select-Object -ExpandProperty "releseVersionDelimiter"
        [regex] $pattern = $mapContext | Select-Object -ExpandProperty "pattern"

        $versionGroups = $pattern.Match($version)

        # Get base version string
        $versionString = $versionGroups.Groups["Version"].Value

        if ($versionGroups.Groups["PreReleaseLabel"].Success) {
            $preReleaseLabel = $versionGroups.Groups["PreReleaseLabel"].Value
            $preReleaseLabelVersion = $versionGroups.Groups["PreReleaseVersion"].Value

            # Get notation for current context
            $preReleaseLabel = $mapContext  | Select-Object -ExpandProperty "releaseNotation" `
                                            | Select-Object -ExpandProperty $preReleaseLabel

            # Format symver correct pre-release version
            $versionString += $preReleaseDelimiter
            $versionString += $preReleaseLabel
            $versionString += $releseVersionDelimiter
            $versionString += $preReleaseLabelVersion
        }   

        return $versionString
    }

    [void] PreparePythonToolcacheLocation() {
        <#
        .SYNOPSIS
        Prepare system hostedtoolcache folder for new Python version. 
        #>
        
        $pythonBinariesLocation = $this.GetFullPythonToolcacheLocation()

        if (Test-Path $pythonBinariesLocation) {
            Write-Host "Purge $pythonBinariesLocation folder..."
            Remove-Item $pythonBinariesLocation -Recurse -Force
        } else {
            Write-Host "Create $pythonBinariesLocation folder..."
            New-Item -ItemType Directory -Path $pythonBinariesLocation 
        }
    }

    ### MOVE TO HELPERS
    [object] GetVersionMapping() {
        $mapFileLocation = Join-Path -Path $this.ConfigsLocation -ChildPath "versions-mapping.json"
        $versionMap = Get-Content -Path $mapFileLocation -Raw | ConvertFrom-Json

        return $versionMap
    }
}
