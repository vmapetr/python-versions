function Convert-Label {
    param(
        [Parameter(Mandatory)]
        [string] $label
    )

    switch ($label) {
        "a" { 
            return "-alpha"
        }
        "b" {
            return "-beta"
        }
        "rc" {
            return "-rc"
        }
        "" {
            return ""
        }
        Default {
            throw "Invalid version label '$label'" 
        }
    }
}

function Convert-LabelNumber {
    param(
        [Parameter(Mandatory)]
        [string] $labelNumber
    )
    return ($labelNumber) ? ".${labelNumber}" : ""
}

function Convert-Version {
    param(
        [Parameter(Mandatory)]
        [string] $version
    )

    $nativePythonPattern = "(?<Version>[\d\.]+)(?<Label>[a-z]+)?(?<LabelNumber>\d+)?"
    $regexResult = [Regex]::Match($version, $nativePythonPattern)
    if (-not $regexResult) { throw "Incorrect version format" }
    
    $version = $regexResult.Groups["Version"].Value
    $semverVersion = "${version}"

    if ($regexResult.Groups["Label"].Success -or $regexResult.Groups["LabelNumber"].Success) {
        $label = Convert-Label $regexResult.Groups["Label"].Value
        $labelNumber = Convert-LabelNumber $regexResult.Groups["LabelNumber"].Value
        $semverVersion += "${label}${labelNumber}"
    }

    return [Semver]::Parse($semverVersion)
}
