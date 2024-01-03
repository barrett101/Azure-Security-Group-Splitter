Start-Transcript -Path C:\temp\GroupSplitter.log

Connect-MgGraph
#Prompts the User for the Main Group Object ID and how many groups it should be split into.
$MainGroupObjectID = Read-Host -Prompt "Please Enter the Main Group Object ID (the one you want to split): "
[int]$TimeToSplit = Read-Host -Prompt "Please Enter how many groups you want to split into?: "
#Retrieve the group members that you want to split
$MainGroup = Get-MgGroupMember -GroupId "$MainGroupObjectID" -All

#Below is the math involved.
$TotalGroupMembers = $MainGroup.count
Write-host "Total Group Members is equal to $TotalGroupMembers take Main Group Object ID $MainGroupObjectID"
write-Host "Total Times to Split is $TimeToSplit"
#Divides members and times to split, rounds down to its whole number and removes one (to factor in the array count starting at 0).
$Divided = [Math]::Floor([decimal](($TotalGroupMembers - 1) / $TimeToSplit))
#Retrieves the remainder of the division above
$Remainder = ($TotalGroupMembers - 1) % $TimeToSplit
Write-Host "First group will have $($Divided + 1), middle groups should have $Divided, the last group should have $($Divided + $remainder)."
Write-Host "Remainder is $Remainder"
Write-Host " "

#Below will prompt user for new group name, create the group, and put the members across each of the groups.
For ($i = 1; $i -le $TimeToSplit; $i++)
{
	$NewGroupName = Read-Host -Prompt "Please Enter the group name ($i of $TimeToSplit):"
	Write-Host "Group $i is called:  $NewGroupName"
	#Creates the new group
	New-MgGroup -DisplayName "$NewGroupName" -MailEnabled:$False -MailNickName 'none' -SecurityEnabled:$True
	#Retrieves the new group details, used to get group ID.
	$NewGroupDetails = Get-MgGroup -Filter "DisplayName eq '$NewGroupName'"
	#First Group
	If ($i -eq 1)
	{
		#Things are different for the first group it defines the starting point for the range to 0.
		$NextGroupFloor = 0
		#Imports the members into the new Group
		$MainGroup[0 .. ($Divided * $i)] | New-MgGroupMember -GroupId $NewGroupDetails.id
		#Writes out the members to host, and into Transcript
		$CountOfNewGroupMembers = $($MainGroup[0 .. ($Divided * $i)]).count
		Write-Host "Below are the $CountOfNewGroupMembers members added to group $NewGroupName"
		Write-Host "--------------------------------------------------------"
		Write-Host $MainGroup[0 .. ($Divided * $i)].AdditionalProperties.userPrincipalName
	}
	#Last Group
	elseif ($i -eq $TimeToSplit)
	{
		#Imports the members into the new Group
		$MainGroup[$NextGroupFloor .. ($NextGroupCeiling + $Remainder)] | New-MgGroupMember -GroupId $NewGroupDetails.id
		#Writes out the members to host, and into Transcript
		$CountOfNewGroupMembers = $($MainGroup[$NextGroupFloor .. ($NextGroupCeiling + $Remainder)]).count
		Write-Host "Below are the $CountOfNewGroupMembers members added to group $NewGroupName"
		Write-Host "--------------------------------------------------------"
		Write-Host $MainGroup[$NextGroupFloor .. ($NextGroupCeiling + $Remainder)].AdditionalProperties.userPrincipalName
	}
	#Middle Groups
	else
	{
		#Imports the members into the new Group
		$MainGroup[$NextGroupFloor .. $NextGroupCeiling] | New-MgGroupMember -GroupId $NewGroupDetails.id
		#Writes out the members to host, and into Transcript
		$CountOfNewGroupMembers = $($MainGroup[$NextGroupFloor .. $NextGroupCeiling]).count
		Write-Host "Below are the $CountOfNewGroupMembers members added to group $NewGroupName"
		Write-Host "--------------------------------------------------------"
		Write-Host $MainGroup[$NextGroupFloor .. $NextGroupCeiling].AdditionalProperties.userPrincipalName
		
	}
	#Will provide the next range for the next group, added if to avoid processing after last group.
	if ($i -ne $TimeToSplit)
	{
		#Prepares for the next group ranges
		$NextGroupFloor = ($Divided * $i) + 1
		$NextGroupCeiling = ($Divided * $i) + $Divided
		Write-Host "Next Group # $($i + 1) FLOOR: $NextGroupFloor"
		Write-Host "Next Group # $($i + 1) CEILING: $NextGroupCeiling, if this is the last group it will add the remainder and actually be" $($NextGroupCeiling + $Remainder)
		Write-Host " "
	}
	$NewGroupName = $null
	$NewGroupDetails = $null
}
Stop-Transcript
