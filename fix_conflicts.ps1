$filePath = 'C:\Users\user\OneDrive\Desktop\cargo\COMPLETE_PRESENTATION_SCRIPT.md'
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
$lines = $content -split "`r?`n"

# Identify conflict block line ranges (0-indexed)
$conflictStarts = @()
$conflictMids = @()
$conflictEnds = @()

for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^<<<<<<< HEAD') { $conflictStarts += $i }
    elseif ($lines[$i] -match '^=======$') { $conflictMids += $i }
    elseif ($lines[$i] -match '^>>>>>>> 8806bf5') { $conflictEnds += $i }
}

# Process conflicts from bottom to top to preserve line numbers
for ($j = $conflictStarts.Count - 1; $j -ge 0; $j--) {
    $startIdx = $conflictStarts[$j]
    $midIdx = $conflictMids[$j]
    $endIdx = $conflictEnds[$j]

    # HEAD lines (between start+1 and mid-1)
    $headLines = $lines[($startIdx+1)..($midIdx-1)]
    # Other lines (between mid+1 and end-1)
    $otherLines = $lines[($midIdx+1)..($endIdx-1)]

    Write-Output "Conflict $($j+1) at lines $($startIdx+1)-$($endIdx+1):"
    Write-Output "  HEAD lines: $($headLines.Count)"
    Write-Output "  OTHER lines: $($otherLines.Count)"

    # Determine resolution based on conflict number
    switch ($j) {
        0 {
            # SSL/Security: keep union of both sides
            $resolved = $headLines + $otherLines
        }
        1 {
            # Geofencing: keep both (HEAD has odometer tracking section, other has geofencing)
            # HEAD: "#### 2. Odometer Tracking" + description
            # OTHER: "#### 2. Geofencing Alerts" + full block
            # Resolution: keep OTHER's geofencing as section 2, HEAD's odometer is already at line 1246 as section 3
            # So we just drop HEAD lines (they duplicate what's at 1246) and keep OTHER
            $resolved = $otherLines
        }
        2 {
            # Emergency Features numbering: HEAD=3, OTHER=4
            # The other branch has geofencing as #2, so emergency is #4
            # HEAD doesn't have geofencing section, so emergency is #3
            # Since we kept geofencing (section 2), emergency should be #4
            $resolved = $otherLines
        }
        3 {
            # Theft notification: keep both lines (union)
            $resolved = $headLines + $otherLines
        }
        4 {
            # Privacy Controls numbering: HEAD=4, OTHER=5
            # Since we now have geofencing(2), odometer(3), emergency(4), privacy=5
            $resolved = $otherLines
        }
        5 {
            # UI/UX reference appendix: HEAD has full content, OTHER is empty
            # Keep HEAD's content
            $resolved = $headLines
        }
    }

    # Replace the conflict block with resolved lines
    $before = $lines[0..($startIdx-1)]
    $after = if ($endIdx + 1 -lt $lines.Length) { $lines[($endIdx+1)..($lines.Length-1)] } else { @() }
    $lines = $before + $resolved + $after
}

# Join and write
$newContent = $lines -join "`n"
[System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.Encoding]::UTF8)
Write-Output "Done! File written."

# Verify no conflicts remain
$remaining = ($newContent -split "`n") | Where-Object { $_ -match '^<<<<<<<|^>>>>>>>|^=======$' }
Write-Output "Remaining conflict markers: $($remaining.Count)"
