$i = 1
Get-ChildItem "assets/images" | ForEach-Object {
    $ext = $_.Extension
    $newName = "$i$ext"
    Rename-Item -Path $_.FullName -NewName $newName
    $i = $i + 1
}
