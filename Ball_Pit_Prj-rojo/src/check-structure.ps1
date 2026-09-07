$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$tree = (Get-Content (Join-Path $root 'default.project.json') -Raw | ConvertFrom-Json).tree

function Assert($condition, [string] $message) {
    if (-not $condition) { throw $message }
}

$maps = @(
    @($tree.ReplicatedStorage.Shared, 'src/shared'),
    @($tree.ServerScriptService.Server, 'src/server'),
    @($tree.StarterPlayer.StarterPlayerScripts.Client, 'src/client')
)
foreach ($map in $maps) {
    Assert ($map[0].'$path' -ceq $map[1]) "Unexpected mapping: $($map[1])"
    Assert (Test-Path (Join-Path $root $map[1]) -PathType Container) "Missing directory: $($map[1])"
}
foreach ($service in @($tree.ReplicatedStorage, $tree.ServerScriptService, $tree.StarterPlayer, $tree.StarterPlayer.StarterPlayerScripts)) {
    Assert ($service.'$ignoreUnknownInstances' -eq $true) 'Unmanaged Studio instances must be preserved'
}
foreach ($old in @('ReplicatedStorage', 'ServerScriptService', 'StarterPlayer')) {
    Assert (-not (Test-Path (Join-Path $PSScriptRoot $old))) "Legacy source directory remains: $old"
}

$targets = @{}
foreach ($group in @('shared/Config', 'server/Modules', 'shared/Remotes')) {
    foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot $group) -File) {
        $name = $file.Name -replace '\.(model\.json|luau)$', ''
        Assert (-not $targets.ContainsKey($name)) "Ambiguous dependency name: $name"
        $targets[$name] = $file.FullName
        if ($group -eq 'shared/Remotes') {
            Assert ($file.Name.EndsWith('.model.json')) "Unexpected remote file: $file"
            Assert ((Get-Content $file.FullName -Raw | ConvertFrom-Json).className -ceq 'RemoteEvent') "Not a RemoteEvent: $file"
        } else {
            Assert ($file.Name -match '^(?!init\.)(?!.*\.(server|client)\.)[^.]+\.luau$') "Not a plain module: $file"
        }
    }
}

# ponytail: checks current literal WaitForChild conventions, not a Luau parser; use a Luau analyzer for dynamic imports.
$checked = 0
foreach ($side in @('client', 'server', 'shared')) {
    foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot $side) -Recurse -File -Filter '*.luau') {
        $source = Get-Content $file.FullName -Raw -Encoding UTF8
        Assert ($source -notmatch 'ReplicatedStorage:WaitForChild\("(ModuleScript|SuctionConfig|RequestSuction|UpdateBag|UpdateCoins|DepositStatus|Script)"\)') "Legacy shared path: $file"
        Assert ($source -notmatch 'script\.Parent(?:\.(BagManager|EconomyManager|DepositCoordinator)|:WaitForChild\("(BagManager|EconomyManager|DepositCoordinator)"\))') "Legacy module path: $file"
        if ($side -eq 'client') {
            Assert (-not $file.Name.EndsWith('.server.luau')) "Server script in client: $file"
            Assert ($source -notmatch 'ServerScriptService|WaitForChild\("Modules"\)') "Client depends on server modules: $file"
        } else {
            Assert (-not $file.Name.EndsWith('.client.luau')) "Client script outside client: $file"
        }
        if ($side -eq 'shared') {
            Assert (-not $file.Name.EndsWith('.server.luau')) "Executable server script in shared: $file"
        }
        foreach ($match in [regex]::Matches($source, ':WaitForChild\("([^"]+)"\)')) {
            $name = $match.Groups[1].Value
            if ($name -match '^.+(Config|Manager|Coordinator)$|^(RequestSuction|UpdateBag|UpdateCoins|DepositStatus)$') {
                Assert ($targets.ContainsKey($name)) "Missing dependency '$name' in $file"
            }
        }
        $checked++
    }
}
Assert ($checked -gt 0) 'No Luau source checked'
Write-Output "PASS: 3 Rojo mappings, $checked Luau files, $($targets.Count) dependency targets. No Rojo or Studio execution."
