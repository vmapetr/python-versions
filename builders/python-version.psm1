function Convert-Version {
    param(
        [Parameter(Mandatory)]
        [semver] $version,
        [char] $delimiter = "."
    )

    $majorVersion = $version.Major
    $minorVersion = $version.Minor
    $patchVersion = $version.Patch

    $nativeVersion = "${majorVersion}.${minorVersion}.${patchVersion}"

    if ($version.PreReleaseLabel)
    {
        $preReleaseLabel = ($version.PreReleaseLabel).Replace("${delimiter}", "")
        $nativeVersion += "${preReleaseLabel}"
    }

    return $nativeVersion
}