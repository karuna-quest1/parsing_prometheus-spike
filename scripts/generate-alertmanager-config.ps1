$ErrorActionPreference = 'Stop'

function Get-EnvFileValues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $values = @{}

    foreach ($line in Get-Content -Path $Path) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $trimmed = $line.Trim()
        if ($trimmed.StartsWith('#')) {
            continue
        }

        if ($trimmed -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
            continue
        }

        $name = $matches[1]
        $value = $matches[2].Trim()

        if (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $values[$name] = $value
    }

    return $values
}

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$envPath = Join-Path $repoRoot '.env'
$templatePath = Join-Path $repoRoot 'alertmanager\alertmanager.yml'
$outputPath = Join-Path $repoRoot 'alertmanager\alertmanager.generated.yml'

if (-not (Test-Path -LiteralPath $envPath)) {
    Write-Error "Missing .env file at $envPath"
}

if (-not (Test-Path -LiteralPath $templatePath)) {
    Write-Error "Missing Alertmanager template at $templatePath"
}

$envValues = Get-EnvFileValues -Path $envPath
$template = Get-Content -Path $templatePath -Raw

$placeholderPattern = '\$\{([A-Za-z_][A-Za-z0-9_]*)\}'
$missing = New-Object System.Collections.Generic.HashSet[string]

[regex]::Matches($template, $placeholderPattern) | ForEach-Object {
    $variableName = $_.Groups[1].Value
    if (-not $envValues.ContainsKey($variableName)) {
        [void]$missing.Add($variableName)
    }
}

if ($missing.Count -gt 0) {
    $missingList = ($missing.ToArray() | Sort-Object) -join ', '
    Write-Error "Missing required .env values for Alertmanager config: $missingList"
}

$generated = [regex]::Replace(
    $template,
    $placeholderPattern,
    {
        param($match)
        return $envValues[$match.Groups[1].Value]
    }
)

$outputDirectory = Split-Path -Path $outputPath -Parent
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

if (Test-Path -LiteralPath $outputPath -PathType Container) {
    $existingEntries = Get-ChildItem -LiteralPath $outputPath -Force
    if ($existingEntries.Count -gt 0) {
        Write-Error "Expected a file at $outputPath, but found a non-empty directory."
    }

    Remove-Item -LiteralPath $outputPath -Force
}

Set-Content -Path $outputPath -Value $generated -Encoding utf8
Write-Host "Generated Alertmanager config at $outputPath"
