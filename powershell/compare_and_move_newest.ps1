$DEST=get-childitem -path "" |
    sort-object -Property $_.CreationTime |
    select-object -last 1 -expandproperty Name

$SRC=get-childitem -path "" |
    sort-object -Property $_.CreationTime |
    select-object -last 1 -expandproperty Name

if ( $DEST -ne $SRC)
{
    Move-Item -Path \$SRC -Destination 
}