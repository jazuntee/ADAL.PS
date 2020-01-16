Set-StrictMode -Version 2.0

function Get-RelativePath {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]] $Paths,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath
    )

    process {
        foreach ($Path in $Paths) {
            if (!$BaseDirectory.EndsWith('\') -and !$BaseDirectory.EndsWith('/')) { $BaseDirectory += '\' }
            [uri] $uriPath = $Path
            [uri] $uriBaseDirectory = $BaseDirectory
            [uri] $uriRelativePath = $uriBaseDirectory.MakeRelativeUri($uriPath)
            [string] $RelativePath = '.\{0}' -f $uriRelativePath.ToString().Replace("/", "\");
            Write-Output $RelativePath
        }
    }
}

function Get-FullPath {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]] $Paths,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath
    )

    process {
        foreach ($Path in $Paths) {
            [string] $AbsolutePath = $Path
            if (![System.IO.Path]::IsPathRooted($AbsolutePath)) {
                $AbsolutePath = (Join-Path $BaseDirectory $AbsolutePath)
            }
            [string] $AbsolutePath = [System.IO.Path]::GetFullPath($AbsolutePath)
            Write-Output $AbsolutePath
        }
    }
}

function Resolve-FullPath {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]] $Paths,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath,
        # Resolves items in all child directories of the specified locations.
        [Parameter(Mandatory=$false)]
        [switch] $Recurse,
        # Resolves items in all parent directories of the specified locations.
        [Parameter(Mandatory=$false)]
        [switch] $RecurseUp
    )

    process {
        foreach ($Path in $Paths) {
            [string] $AbsolutePath = $Path
            if (![System.IO.Path]::IsPathRooted($AbsolutePath)) {
                $AbsolutePath = (Join-Path $BaseDirectory $AbsolutePath)
            }
            [string[]] $AbsoluteOutputPaths = Resolve-Path $AbsolutePath
            if ($Recurse) {
                $RecurseBaseDirectory = Join-Path (Split-Path $AbsolutePath -Parent) "**"
                $RecurseFilename = Split-Path $AbsolutePath -Leaf
                $RecursePath = Join-Path $RecurseBaseDirectory $RecurseFilename
                $AbsoluteOutputPaths += Resolve-Path $RecursePath
            }
            if ($RecurseUp) {
                $RecurseBaseDirectory = Split-Path $AbsolutePath -Parent
                $RecurseFilename = Split-Path $AbsolutePath -Leaf
                while ($RecurseBaseDirectory -match "[\\/]") {
                    $RecurseBaseDirectory = Split-Path $RecurseBaseDirectory -Parent
                    if ($RecurseBaseDirectory) {
                        $RecursePath = Join-Path $RecurseBaseDirectory $RecurseFilename
                        $AbsoluteOutputPaths += Resolve-Path $RecursePath
                    }
                }
            }
            Write-Output $AbsoluteOutputPaths
        }
    }
}

function Get-PathInfo {
    [CmdletBinding()]
    param (
        # Input Paths
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [AllowEmptyString()]
        [string[]] $Paths,
        # Specifies the type of output path when the path does not exist. By default, it will guess path type. If path exists, this parameter is ignored.
        [Parameter(Mandatory=$false, Position=2)]
        [ValidateSet("Directory", "File")]
        [string] $InputPathType,
        # Root directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=3)]
        [string] $DefaultDirectory = (Get-Location).ProviderPath,
        # Filename to append to path if no filename is present.
        [Parameter(Mandatory=$false, Position=4)]
        [string] $DefaultFilename,
        #
        [Parameter(Mandatory=$false)]
        [switch] $SkipEmptyPaths
    )

    process {
        foreach ($Path in $Paths) {

            if (!$SkipEmptyPaths -and !$Path) { $Path = $DefaultDirectory }
            $OutputPath = $null

            if ($Path) {
                ## Look for existing path
                try {
                    $ResolvePath = Resolve-FullPath $Path -BaseDirectory $DefaultDirectory -ErrorAction SilentlyContinue
                    $OutputPath = Get-Item $ResolvePath -ErrorAction SilentlyContinue
                }
                catch {}
                ## If path could not be found and there are no wildcards, then create a FileSystemInfo object for the path.
                if (!$OutputPath -and $Path -notmatch '[*?]') {
                    ## Get Absolute Path
                    [string] $AbsolutePath = Get-FullPath $Path -BaseDirectory $DefaultDirectory
                    ## Guess if path is File or Directory
                    if ($InputPathType -eq "File" -or (!$InputPathType -and $AbsolutePath -match '[\\/](?!.*[\\/]).+\.(?!\.*$).*[^\\/]$')) {
                        $OutputPath = New-Object System.IO.FileInfo -ArgumentList $AbsolutePath
                    }
                    else {
                        $OutputPath = New-Object System.IO.DirectoryInfo -ArgumentList $AbsolutePath
                    }
                }
                ## If a DefaultFilename was provided and no filename was present in path, then add the default.
                if ($DefaultFilename -and $OutputPath -is [System.IO.DirectoryInfo]) {
                    [string] $AbsolutePath = (Join-Path $OutputPath.FullName $DefaultFileName)
                    $OutputPath = $null
                    try {
                        $ResolvePath = Resolve-FullPath $AbsolutePath -BaseDirectory $DefaultDirectory -ErrorAction SilentlyContinue
                        $OutputPath = Get-Item $ResolvePath -ErrorAction SilentlyContinue
                    }
                    catch {}
                    if (!$OutputPath -and $AbsolutePath -notmatch '[*?]') {
                        $OutputPath = New-Object System.IO.FileInfo -ArgumentList $AbsolutePath
                    }
                }

                if (!$OutputPath -or !$OutputPath.Exists) {
                    if ($OutputPath) { Write-Error -Exception (New-Object System.Management.Automation.ItemNotFoundException -ArgumentList ('Cannot find path ''{0}'' because it does not exist.' -f $OutputPath.FullName)) -TargetObject $OutputPath.FullName -ErrorId 'PathNotFound' -Category ObjectNotFound }
                    else { Write-Error -Exception (New-Object System.Management.Automation.ItemNotFoundException -ArgumentList ('Cannot find path ''{0}'' because it does not exist.' -f $AbsolutePath)) -TargetObject $AbsolutePath -ErrorId 'PathNotFound' -Category ObjectNotFound }
                }
            }

            ## Return Path Info
            Write-Output $OutputPath
        }
    }
}

function Assert-DirectoryExists {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        # Directories
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [object[]] $InputObjects,
        # Directory to base relative paths. Default is current directory.
        [Parameter(Mandatory=$false, Position=2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath
    )
    process {
        foreach ($InputObject in $InputObjects) {
            ## InputObject Casting
            if($InputObject -is [System.IO.DirectoryInfo]) {
                [System.IO.DirectoryInfo] $DirectoryInfo = $InputObject
            }
            elseif($InputObject -is [System.IO.FileInfo]) {
                [System.IO.DirectoryInfo] $DirectoryInfo = $InputObject.Directory
            }
            elseif ($InputObject -is [string]) {
                [System.IO.DirectoryInfo] $DirectoryInfo = $InputObject
            }

            if (!$DirectoryInfo.Exists) {
                Write-Output (New-Item $DirectoryInfo.FullName -ItemType Container)
            }
        }
    }
}

function New-LogFilename ([string] $Path) { return ('{0}.{1}.log' -f $Path, (Get-Date -Format "yyyyMMddThhmmss")) }
function Get-ExtractionFolder ([System.IO.FileInfo] $Path) { return Join-Path $Path.DirectoryName $Path.BaseName }

function Use-StartBitsTransfer {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        # Specifies the source location and the names of the files that you want to transfer.
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Source,
        # Specifies the destination location and the names of the files that you want to transfer.
        [Parameter(Mandatory=$false, Position=1)]
        [string] $Destination,
        # Specifies the proxy usage settings
        [Parameter(Mandatory=$false, Position=3)]
        [ValidateSet('SystemDefault','NoProxy','AutoDetect','Override')]
        [string] $ProxyUsage,
        # Specifies a list of proxies to use
        [Parameter(Mandatory=$false, Position=4)]
        [uri[]] $ProxyList,
        # Specifies the authentication mechanism to use at the Web proxy
        [Parameter(Mandatory=$false, Position=5)]
        [ValidateSet('Basic','Digest','NTLM','Negotiate','Passport')]
        [string] $ProxyAuthentication,
        # Specifies the credentials to use to authenticate the user at the proxy
        [Parameter(Mandatory=$false, Position=6)]
        [pscredential] $ProxyCredential,
        # Returns an object representing transfered item.
        [Parameter(Mandatory=$false)]
        [switch] $PassThru
    )
    [hashtable] $paramStartBitsTransfer = $PSBoundParameters
    foreach ($Parameter in $PSBoundParameters.Keys) {
        if ($Parameter -notin 'ProxyUsage','ProxyList','ProxyAuthentication','ProxyCredential') {
            $paramStartBitsTransfer.Remove($Parameter)
        }
    }

    if (!$Destination) { $Destination = (Get-Location).ProviderPath }
    if (![System.IO.Path]::HasExtension($Destination)) { $Destination = Join-Path $Destination (Split-Path $Source -Leaf) }
    if (Test-Path $Destination) { Write-Verbose ('The Source [{0}] was not transfered to Destination [{0}] because it already exists.' -f $Source, $Destination) }
    else {
        Write-Verbose ('Downloading Source [{0}] to Destination [{1}]' -f $Source, $Destination);
        Start-BitsTransfer $Source $Destination @paramStartBitsTransfer
    }
    if ($PassThru) { return Get-Item $Destination }
}

function Use-StartProcess {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        # Specifies the path (optional) and file name of the program that runs in the process.
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FilePath,
        # Specifies parameters or parameter values to use when starting the process.
        [Parameter(Mandatory=$false)]
        [string[]] $ArgumentList,
        # Specifies the working directory for the process.
        [Parameter(Mandatory=$false)]
        [string] $WorkingDirectory,
        # Specifies a user account that has permission to perform this action.
        [Parameter(Mandatory=$false)]
        [pscredential] $Credential,
        # Regex pattern in cmdline to replace with '**********'
        [Parameter(Mandatory=$false)]
        [string[]] $SensitiveDataFilters
    )
    [hashtable] $paramStartProcess = $PSBoundParameters
    foreach ($Parameter in $PSBoundParameters.Keys) {
        if ($Parameter -in 'SensitiveDataFilters') {
            $paramStartProcess.Remove($Parameter)
        }
    }
    [string] $cmd = '"{0}" {1}' -f $FilePath, ($ArgumentList -join ' ')
    foreach ($Filter in $SensitiveDataFilters) {
        $cmd = $cmd -replace $Filter,'**********'
    }
    if ($PSCmdlet.ShouldProcess([System.Environment]::MachineName, $cmd)) {
        [System.Diagnostics.Process] $process = Start-Process -PassThru -Wait -NoNewWindow @paramStartProcess
        if ($process.ExitCode -ne 0) { Write-Error -Category FromStdErr -CategoryTargetName (Split-Path $FilePath -Leaf) -CategoryTargetType "Process" -TargetObject $cmd -CategoryReason "Exit Code not equal to 0" -Message ('Process [{0}] with Id [{1}] terminated with Exit Code [{2}]' -f $FilePath, $process.Id, $process.ExitCode) }
    }
}

function Invoke-WindowsInstaller {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        # Path to msi or msp
        [Parameter(Mandatory=$true, Position=0)]
        [System.IO.FileInfo] $Path,
        # Sets user interface level
        [Parameter(Mandatory=$false)]
        [ValidateSet('None','Basic','Reduced','Full')]
        [string] $UserInterfaceMode,
        # Restart Options
        [Parameter(Mandatory=$false)]
        [ValidateSet('No','Prompt','Force')]
        [string] $RestartOptions,
        # Logging Options
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^[iwearucmopvx\+!\*]{0,14}$')]
        [string] $LoggingOptions,
        # Path of log file
        [Parameter(Mandatory=$false)]
        [System.IO.FileInfo] $LogPath,
        # Public Properties
        [Parameter(Mandatory=$false)]
        [hashtable] $PublicProperties,
        # Specifies the working directory for the process.
        [Parameter(Mandatory=$false)]
        [string] $WorkingDirectory,
        # Regex pattern in cmdline to replace with '**********'
        [Parameter(Mandatory=$false)]
        [string[]] $SensitiveDataFilters
    )

    [System.IO.FileInfo] $itemLogPath = (Get-Location).ProviderPath
    if ($LogPath) { $itemLogPath = $LogPath }
    if (!$itemLogPath.Extension) { $itemLogPath = Join-Path $itemLogPath.FullName ('{0}.{1}.log' -f (Split-Path $Path -Leaf),(Get-Date -Format "yyyyMMddThhmmss")) }

    ## Windows Installer Arguments
    [System.Collections.Generic.List[string]] $argMsiexec = New-Object "System.Collections.Generic.List[string]"
    switch ($UserInterfaceMode)
    {
        'None' { $argMsiexec.Add('/qn'); break }
        'Basic' { $argMsiexec.Add('/qb'); break }
        'Reduced' { $argMsiexec.Add('/qr'); break }
        'Full' { $argMsiexec.Add('/qf'); break }
    }

    switch ($Restart)
    {
        'No' { $argMsiexec.Add('/norestart'); break }
        'Prompt' { $argMsiexec.Add('/promptrestart'); break }
        'Force' { $argMsiexec.Add('/forcerestart'); break }
    }

    if ($LoggingOptions -or $LogPath) { $argMsiexec.Add(('/l{0} "{1}"' -f $LoggingOptions, $itemLogPath.FullName)) }
    switch ($Path.Extension)
    {
        '.msi' { $argMsiexec.Add('/i "{0}"' -f $Path); break }
        '.msp' { $argMsiexec.Add('/update "{0}"' -f $Path); break }
        Default { $argMsiexec.Add('/i "{0}"' -f $Path); break }
    }

    foreach ($PropertyKey in $PublicProperties.Keys) {
        $argMsiexec.Add(('{0}="{1}"' -f $PropertyKey.ToUpper(), $PublicProperties[$PropertyKey]))
    }

    [hashtable] $paramStartProcess = @{}
    if ($argMsiexec) { $paramStartProcess["ArgumentList"] = $argMsiexec }
    if ($WorkingDirectory) { $paramStartProcess["WorkingDirectory"] = $WorkingDirectory }

    Use-StartProcess msiexec @paramStartProcess
}

function ConvertTo-PsString {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        #
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [AllowNull()]
        [object] $InputObjects,
        #
        [Parameter(Mandatory=$false)]
        [switch] $Compact,
        #
        [Parameter(Mandatory=$false, Position=1)]
        [type[]] $RemoveTypes = ([string],[bool],[int],[long]),
        #
        [Parameter(Mandatory=$false)]
        [switch] $NoEnumerate
    )

    begin {
        if ($Compact) {
            [System.Collections.Generic.Dictionary[string,type]] $TypeAccelerators = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::get
            [System.Collections.Generic.Dictionary[type,string]] $TypeAcceleratorsLookup = New-Object 'System.Collections.Generic.Dictionary[type,string]'
            foreach ($TypeAcceleratorKey in $TypeAccelerators.Keys) {
                if (!$TypeAcceleratorsLookup.ContainsKey($TypeAccelerators[$TypeAcceleratorKey])) {
                    $TypeAcceleratorsLookup.Add($TypeAccelerators[$TypeAcceleratorKey],$TypeAcceleratorKey)
                }
            }
        }

        function Resolve-Type {
            param (
                #
                [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
                [type] $ObjectType,
                #
                [Parameter(Mandatory=$false, Position=1)]
                [switch] $Compact,
                #
                [Parameter(Mandatory=$false, Position=1)]
                [type[]] $RemoveTypes
            )

            [string] $OutputString = ''
            if ($ObjectType.IsGenericType) {
                if ($ObjectType.FullName.StartsWith('System.Collections.Generic.Dictionary')) {
                    #$OutputString += '[hashtable]'
                    if ($Compact) {
                        $OutputString += '(Invoke-Command { $D = New-Object ''Collections.Generic.Dictionary['
                    }
                    else {
                        $OutputString += '(Invoke-Command { $D = New-Object ''System.Collections.Generic.Dictionary['
                    }
                    $iInput = 0
                    foreach ($GenericTypeArgument in $ObjectType.GenericTypeArguments) {
                        if ($iInput -gt 0) { $OutputString += ',' }
                        $OutputString += Resolve-Type $GenericTypeArgument -Compact:$Compact -RemoveTypes @()
                        $iInput++
                    }
                    $OutputString += ']'''
                }
                elseif ($InputObject.GetType().FullName -match '^(System.(Collections.Generic.[a-zA-Z]+))`[0-9]\[(?:\[(.+?), .+?, Version=.+?, Culture=.+?, PublicKeyToken=.+?\],?)+?\]$') {
                    if ($Compact) {
                        $OutputString += '[{0}[' -f $Matches[2]
                    }
                    else {
                        $OutputString += '[{0}[' -f $Matches[1]
                    }
                    $iInput = 0
                    foreach ($GenericTypeArgument in $ObjectType.GenericTypeArguments) {
                        if ($iInput -gt 0) { $OutputString += ',' }
                        $OutputString += Resolve-Type $GenericTypeArgument -Compact:$Compact -RemoveTypes @()
                        $iInput++
                    }
                    $OutputString += ']]'
                }
            }
            elseif ($ObjectType -eq [System.Collections.Specialized.OrderedDictionary]) {
                $OutputString += '[ordered]'  # Explicit cast does not work with full name. Only [ordered] works.
            }
            elseif ($Compact) {
                if ($ObjectType -notin $RemoveTypes) {
                    if ($TypeAcceleratorsLookup.ContainsKey($ObjectType)) {
                        $OutputString += '[{0}]' -f $TypeAcceleratorsLookup[$ObjectType]
                    }
                    elseif ($ObjectType.FullName.StartsWith('System.')) {
                        $OutputString += '[{0}]' -f $ObjectType.FullName.Substring(7)
                    }
                    else {
                        $OutputString += '[{0}]' -f $ObjectType.FullName
                    }
                }
            }
            else {
                $OutputString += '[{0}]' -f $ObjectType.FullName
            }
            return $OutputString
        }

        function GetPSString ($InputObject) {
            $OutputString = New-Object System.Text.StringBuilder

            if ($null -eq $InputObject) { [void]$OutputString.Append('$null') }
            else {
                ## Add Casting
                [void]$OutputString.Append((Resolve-Type $InputObject.GetType() -Compact:$Compact -RemoveTypes $RemoveTypes))

                ## Add Value
                switch ($InputObject.GetType())
                {
                    {$_.Equals([String])} {
                        [void]$OutputString.AppendFormat("'{0}'",$InputObject.Replace("'","''")) #.Replace('"','`"')
                        break }
                    {$_.Equals([Char])} {
                        [void]$OutputString.AppendFormat("'{0}'",([string]$InputObject).Replace("'","''"))
                        break }
                    {$_.Equals([Boolean]) -or $_.Equals([switch])} {
                        [void]$OutputString.AppendFormat('${0}',$InputObject)
                        break }
                    {$_.Equals([DateTime])} {
                        [void]$OutputString.AppendFormat("'{0}'",$InputObject.ToString('O'))
                        break }
                    {$_.BaseType.Equals([Enum])} {
                        [void]$OutputString.AppendFormat('::{0}',$InputObject)
                        break }
                    {$_.BaseType.Equals([ValueType])} {
                        [void]$OutputString.AppendFormat('{0}',$InputObject)
                        break }
                    {$_.Equals([System.Xml.XmlDocument])} {
                        [void]$OutputString.AppendFormat("'{0}'",$InputObject.OuterXml.Replace("'","''")) #.Replace('"','""')
                        break }
                    {$_.Equals([Hashtable]) -or $_.Equals([System.Collections.Specialized.OrderedDictionary])} {
                        [void]$OutputString.Append('@{')
                        $iInput = 0
                        foreach ($enumHashtable in $InputObject.GetEnumerator()) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(';') }
                            [void]$OutputString.AppendFormat('{0}={1}',(ConvertTo-PsString $enumHashtable.Key -Compact:$Compact -NoEnumerate),(ConvertTo-PsString $enumHashtable.Value -Compact:$Compact -NoEnumerate))
                            $iInput++
                        }
                        [void]$OutputString.Append('}')
                        break }
                    {$_.FullName.StartsWith('System.Collections.Generic.Dictionary')} {
                        $iInput = 0
                        foreach ($enumHashtable in $InputObject.GetEnumerator()) {
                            [void]$OutputString.AppendFormat('; $D.Add({0},{1})',(ConvertTo-PsString $enumHashtable.Key -Compact:$Compact -NoEnumerate),(ConvertTo-PsString $enumHashtable.Value -Compact:$Compact -NoEnumerate))
                            $iInput++
                        }
                        [void]$OutputString.Append('; $D })')
                        break }
                    {$_.BaseType.Equals([Array])} {
                        [void]$OutputString.Append('(Write-Output @(')
                        $iInput = 0
                        for ($iInput = 0; $iInput -lt $InputObject.Count; $iInput++) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(',') }
                            [void]$OutputString.Append((ConvertTo-PsString $InputObject[$iInput] -Compact:$Compact -RemoveTypes $InputObject.GetType().DeclaredMembers.Where({$_.Name -eq 'Set'})[0].GetParameters()[1].ParameterType -NoEnumerate))
                        }
                        [void]$OutputString.Append(') -NoEnumerate)')
                        break }
                    {$_.Equals([System.Collections.ArrayList])} {
                        [void]$OutputString.Append('@(')
                        $iInput = 0
                        for ($iInput = 0; $iInput -lt $InputObject.Count; $iInput++) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(',') }
                            [void]$OutputString.Append((ConvertTo-PsString $InputObject[$iInput] -Compact:$Compact -NoEnumerate))
                        }
                        [void]$OutputString.Append(')')
                        break }
                    {$_.FullName.StartsWith('System.Collections.Generic.List')} {
                        [void]$OutputString.Append('@(')
                        $iInput = 0
                        for ($iInput = 0; $iInput -lt $InputObject.Count; $iInput++) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(',') }
                            [void]$OutputString.Append((ConvertTo-PsString $InputObject[$iInput] -Compact:$Compact -RemoveTypes $_.GenericTypeArguments -NoEnumerate))
                        }
                        [void]$OutputString.Append(')')
                        break }
                    ## Convert objects with object initializers
                    {$_ -is [object] -and ($_.GetConstructors() | foreach { if ($_.IsPublic -and !$_.GetParameters()) { $true } })} {
                        [void]$OutputString.Append('@{')
                        $iInput = 0
                        foreach ($Item in ($InputObject | Get-Member -MemberType Property,NoteProperty)) {
                            if ($iInput -gt 0) { [void]$OutputString.Append(';') }
                            $PropertyName = $Item.Name
                            [void]$OutputString.AppendFormat('{0}={1}',(ConvertTo-PsString $PropertyName -Compact:$Compact -NoEnumerate),(ConvertTo-PsString $InputObject.$PropertyName -Compact:$Compact -NoEnumerate))
                            $iInput++
                        }
                        [void]$OutputString.Append('}')
                        break }
                    Default {
                        $Exception = New-Object ArgumentException -ArgumentList ('Cannot convert input of type {0} to PowerShell string.' -f $InputObject.GetType())
                        Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ParserError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'ConvertPowerShellStringFailureTypeNotSupported' -TargetObject $InputObject
                    }
                }
            }

            if ($NoEnumerate) {
                $listOutputString.Add($OutputString.ToString())
            }
            else {
                Write-Output $OutputString.ToString()
            }
        }

        if ($NoEnumerate) {
            $listOutputString = New-Object System.Collections.Generic.List[string]
        }
    }

    process {
        if ($PSCmdlet.MyInvocation.ExpectingInput -or $NoEnumerate -or $null -eq $InputObjects) {
            GetPSString $InputObjects
        }
        else {
            foreach ($InputObject in $InputObjects) {
                GetPSString $InputObject
            }
        }
    }

    end {
        if ($NoEnumerate) {
            if (($null -eq $InputObjects -and $listOutputString.Count -eq 0) -or $listOutputString.Count -gt 1) {
                Write-Warning ('To avoid losing strong type on outermost enumerable type when piping, use "Write-Output $Array -NoEnumerate | {0}".' -f $MyInvocation.MyCommand)
                $OutputArray = New-Object System.Text.StringBuilder
                [void]$OutputArray.Append('(Write-Output @(')
                if ($PSVersionTable.PSVersion -ge [version]'6.0') {
                    [void]$OutputArray.AppendJoin(',',$listOutputString)
                }
                else {
                    [void]$OutputArray.Append(($listOutputString -join ','))
                }
                [void]$OutputArray.Append(') -NoEnumerate)')
                Write-Output $OutputArray.ToString()
            }
            else {
                Write-Output $listOutputString[0]
            }

        }
    }
}

