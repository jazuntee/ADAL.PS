
Remove-Module ADAL.PS -ErrorAction SilentlyContinue
Import-Module ..\src\ADAL.PS.psd1

Get-ADALToken -Resource 'https://graph.microsoft.com/' #-PromptBehavior Always -UserId $User
