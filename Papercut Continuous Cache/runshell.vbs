Dim Arg, NetworkPath, Silent, Shell, Script

Set Arg = WScript.Arguments

NetworkPath = Arg(0)
Silent = Arg(1)
Script = Arg(2)

sCMD = "powershell.exe -nologo -ExecutionPolicy bypass -file """ & Script & """ -NetworkPath """ & NetworkPath & """ -Silent """ & Silent & """"
Set shell = CreateObject("WScript.Shell")

shell.Run sCMD,0