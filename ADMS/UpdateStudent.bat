set ScriptPath="C:\AdmsScripts\Batch_PowerShell_Passthrough.ps1"
set Type=UpdateStudent
powershell -command "%ScriptPath% %2 %Type%"