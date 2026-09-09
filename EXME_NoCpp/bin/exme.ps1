param(
    [Parameter(Position=0)]
    [string]$Source,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    [Console]::Error.WriteLine("EXME compile error: $Message")
    exit 1
}

function Strip-Comment([string]$Line) {
    $p = $Line.IndexOf('```')
    if ($p -ge 0) { return $Line.Substring(0, $p) }
    return $Line
}

function Parse-U64([string]$Text, [string]$What) {
    if ([string]::IsNullOrWhiteSpace($Text)) { throw "missing $What" }
    $t = $Text.Trim()
    try {
        if ($t.StartsWith('0x', [System.StringComparison]::OrdinalIgnoreCase)) {
            return [Convert]::ToUInt64($t.Substring(2), 16)
        }
        return [Convert]::ToUInt64($t, 10)
    } catch {
        throw "invalid $What`: $Text"
    }
}

function Split-Fields([string]$Payload) {
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($part in ($Payload -split '\\')) {
        $t = $part.Trim()
        if ($t.Length -gt 0) { $list.Add($t) }
    }
    return ,$list.ToArray()
}

function Get-Field([string[]]$Fields, [char]$Prefix, [bool]$Required=$true) {
    $found = $null
    $count = 0
    foreach ($f in $Fields) {
        if ($f.Length -gt 0 -and [char]::ToUpperInvariant($f[0]) -eq [char]::ToUpperInvariant($Prefix)) {
            $count++
            $found = $f.Substring(1)
        }
    }
    if ($count -gt 1) { throw "duplicate field $Prefix" }
    if ($count -eq 0 -and $Required) { throw "missing field $Prefix" }
    return $found
}

function Reject-Unknown([string[]]$Fields, [string]$Allowed) {
    foreach ($f in $Fields) {
        if ($f.Length -eq 0) { continue }
        $c = [char]::ToUpperInvariant($f[0])
        if ($Allowed.IndexOf($c) -lt 0) { throw "unknown field: $f" }
    }
}

function Parse-Hex([string]$Text) {
    $clean = [regex]::Replace($Text, '[\s_]', '')
    if (($clean.Length % 2) -ne 0) { throw 'X field must contain complete bytes' }
    if ($clean.Length -gt 0 -and $clean -notmatch '^[0-9A-Fa-f]+$') { throw 'X field contains non-hex characters' }
    $bytes = [byte[]]::new([int]($clean.Length / 2))
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = [Convert]::ToByte($clean.Substring($i * 2, 2), 16)
    }
    return ,$bytes
}

function Load-With-Imports([string]$File, [System.Collections.Generic.HashSet[string]]$Seen) {
    $full = [System.IO.Path]::GetFullPath($File)
    if (-not $Seen.Add($full.ToLowerInvariant())) { throw "recursive/duplicate import: $full" }
    if (-not [System.IO.File]::Exists($full)) { throw "cannot open EXME source: $full" }

    $builder = [System.Text.StringBuilder]::new()
    $dir = [System.IO.Path]::GetDirectoryName($full)
    foreach ($line in [System.IO.File]::ReadAllLines($full)) {
        $clean = Strip-Comment $line
        $m = [regex]::Match($clean, '^\s*~import\s+"([^"]+)"\s*~\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($m.Success) {
            $child = [System.IO.Path]::Combine($dir, $m.Groups[1].Value)
            [void]$builder.Append((Load-With-Imports $child $Seen))
            [void]$builder.Append("`n")
        } else {
            [void]$builder.Append($line)
            [void]$builder.Append("`n")
        }
    }
    return $builder.ToString()
}

function Strip-All-Comments([string]$SourceText) {
    $builder = [System.Text.StringBuilder]::new()
    $first = $true
    foreach ($line in ($SourceText -split "`r?`n", 0, 'RegexMatch')) {
        if (-not $first) { [void]$builder.Append("`n") }
        $first = $false
        [void]$builder.Append((Strip-Comment $line))
    }
    return $builder.ToString()
}

function Parse-Write([char]$Kind, [string]$Payload, [int]$Index) {
    $fields = Split-Fields $Payload
    Reject-Unknown $fields 'OBX'
    $offset = Parse-U64 (Get-Field $fields 'O') 'O offset'
    $count = Parse-U64 (Get-Field $fields 'B') 'B byte count'
    $bytes = Parse-Hex (Get-Field $fields 'X')
    if ([uint64]$bytes.Length -ne $count) {
        throw "B says $count bytes but X contains $($bytes.Length)"
    }
    return [pscustomobject]@{ Kind=$Kind; Offset=$offset; Bytes=$bytes; Index=$Index }
}

try {
    if ($Source -eq '--version') {
        [Console]::Out.WriteLine('EXME manual 2.1')
        exit 0
    }
    if ([string]::IsNullOrWhiteSpace($Source) -or $Source -eq '--help' -or $Source -eq '-h') {
        [Console]::Out.WriteLine('EXME manual compiler')
        [Console]::Out.WriteLine('usage: exme <source.exme> -o <output>')
        exit $(if ([string]::IsNullOrWhiteSpace($Source)) { 1 } else { 0 })
    }

    $output = $null
    for ($i = 0; $i -lt $Rest.Count; $i++) {
        $a = $Rest[$i]
        if ($a -eq '-o') {
            $i++
            if ($i -ge $Rest.Count) { throw '-o requires an output file' }
            $output = $Rest[$i]
        } elseif ($a.StartsWith('-')) {
            throw "unknown option: $a"
        } else {
            throw "unexpected argument: $a"
        }
    }

    if (-not $Source.EndsWith('.exme', [System.StringComparison]::OrdinalIgnoreCase)) { throw 'EXME source files must use .exme' }
    if ([string]::IsNullOrWhiteSpace($output)) { throw 'you must provide -o; EXME will not choose an output name for you' }

    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $expanded = Load-With-Imports $Source $seen
    $text = Strip-All-Comments $expanded

    $fileMatches = [regex]::Matches($text, '~file\s*\\([^~]+)~', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($fileMatches.Count -eq 0) { throw 'missing ~file\B...\F..~ directive; EXME will not choose a file size for you' }
    if ($fileMatches.Count -gt 1) { throw 'only one ~file...~ directive is allowed' }

    $fileFields = Split-Fields $fileMatches[0].Groups[1].Value
    Reject-Unknown $fileFields 'BF'
    $fileBytes = Parse-U64 (Get-Field $fileFields 'B') 'file B size'
    $fillBytes = Parse-Hex (Get-Field $fileFields 'F')
    if ($fillBytes.Length -ne 1) { throw 'F must be exactly one byte, e.g. F00 or FCC' }
    $fill = $fillBytes[0]

    if ($fileBytes -gt [int]::MaxValue) { throw 'output file is too large for this Windows EXME compiler' }

    $combined = '(?is)(?<data>~data\s*\\(?<datapayload>[^~]+)~)|(?<op>\*@(?<kind>[WGMJ])\s*<(?<oppayload>.*?)>\$)'
    $matches = [regex]::Matches($text, $combined)
    $writes = [System.Collections.Generic.List[object]]::new()

    foreach ($m in $matches) {
        if ($m.Groups['data'].Success) {
            $writes.Add((Parse-Write 'D' $m.Groups['datapayload'].Value $m.Index))
        } else {
            $kind = [char]::ToUpperInvariant($m.Groups['kind'].Value[0])
            $writes.Add((Parse-Write $kind $m.Groups['oppayload'].Value $m.Index))
        }
    }

    $image = [byte[]]::new([int]$fileBytes)
    if ($fill -ne 0) {
        for ($i = 0; $i -lt $image.Length; $i++) { $image[$i] = $fill }
    }

    foreach ($w in $writes) {
        if ($w.Offset -gt $fileBytes -or [uint64]$w.Bytes.Length -gt ($fileBytes - $w.Offset)) {
            throw "$($w.Kind) write exceeds manually declared file size"
        }
        [Array]::Copy($w.Bytes, 0, $image, [int]$w.Offset, $w.Bytes.Length)
    }

    $outFull = [System.IO.Path]::GetFullPath($output)
    $outDir = [System.IO.Path]::GetDirectoryName($outFull)
    if ($outDir -and -not [System.IO.Directory]::Exists($outDir)) { [System.IO.Directory]::CreateDirectory($outDir) | Out-Null }
    [System.IO.File]::WriteAllBytes($outFull, $image)
    exit 0
} catch {
    Fail $_.Exception.Message
}
