get-childitem -path (Select-String -Path -Pattern "").Path |
    sort-object -Property $_.CreationTime |
    select-object -last 1 |
    Copy-Item -Destination 