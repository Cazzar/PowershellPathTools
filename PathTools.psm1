Function CheckAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

<# 
 .Synopsis
  Gets the list of current folders on the PATH variable for the specified scope

 .Description
  Returns an array of folders which is currently used in the PATH variable for the given
  scope, allowing for easy scripting, already pre-split between semicolons

 .Parameter Scope
   The scope to get the information from the Environment from, this can be any of:
    - Process
    - User
    - Machine 
   
 .Example
   # Show a list of anything within $PATH.
   Get-Path

 .Example
   # Display the information for the System level.
   Get-Path -Scope Machine
#>
Function Get-Path {
    [CmdletBinding()]
    Param(
        [System.EnvironmentVariableTarget] $Scope = 'Process'
    )     
    process {
        return [System.Environment]::GetEnvironmentVariable("PATH", $Scope).Split(';');
    }
}

<# 
 .Synopsis
  Gets if the path is within the given PATH environment 

 .Description
  iterates through the entire given path environment checking if it currently exists, used well for reducing duplicates.

 .Parameter Scope
   The scope to get the information from the Environment from, this can be any of:
    - Process
    - User
    - Machine 
    
  .Parameter Path
    The path to check.
   
 .Example
   # Check if C:\Foo is on the Process path scope.
   Find-Path C:\Foo

 .Example
   # Check if C:\Foo is on the User path scope.
   Find-Path C:\Foo -Scope User
#>
Function Find-Path {
    Param(
        [string] $Path,
        [System.EnvironmentVariableTarget] $Scope = 'Process'
    )
    process {
        $OurPath = Get-Path -Scope $Scope
        for ($i = 0; $i -lt $OurPath.Count; $i++) {
            if ($OurPath[$i] -ieq $Path) { return $i }
        }
        return $false
    }
}


<# 
 .Synopsis
  Add the path to the given PATH environment 

 .Description
  Checks if the passed paths are in the PATH adding them if they are not in the path, ignoring them if they are in the path.

 .Parameter Scope
   The scope to get the information from the Environment from, this can be any of:
    - Process
    - User
    - Machine 
    
  .Parameter Path
    The path(s) to check.
   
 .Example
   # Add C:\Foo into the Process path scope.
   Push-Path C:\Foo

 .Example
   # Add C:\Foo into the User path scope.
   Push-Path C:\Foo -Scope User
#>
Function Push-Path {
    [CmdletBinding()]
    Param(
        [string[]] $Path,
        [System.EnvironmentVariableTarget] $Scope = 'Process'
    )
    process {
        if ($Scope -eq [System.EnvironmentVariableTarget]::Machine -and !(CheckAdmin)) {
            Write-Error "To set for the system scope you have to run as admin!"
            return;
        }

        $m_Path = Get-Path -Scope $Scope
        foreach ($m_sPath in $Path) {
            if (!(Test-Path -PathType Container -LiteralPath $m_sPath)) {
                Write-Warning "The path $m_sPath must exist AND be a folder... ignoring"
                continue
            }
            if (Find-Path -Scope $Scope -Path $m_sPath) { 
                Write-Verbose "$m_sPath is already in the path... ignoring"
                continue
            }
            $m_Path += $m_sPath;
        }
        
        [System.Environment]::SetEnvironmentVariable("PATH", [string]::Join(';', $m_Path), $Scope)
    }
}

<# 
 .Synopsis
  Remove the path from the given PATH environment 

 .Description
  Checks if the passed paths are in the PATH removing them if they are in the path, ignoring them if they are not in the path.

 .Parameter Scope
   The scope to get the information from the Environment from, this can be any of:
    - Process
    - User
    - Machine 
    
  .Parameter Path
    The path(s) to check.
   
 .Example
   # Remove C:\Foo from the Process path scope.
   Push-Path C:\Foo

 .Example
   # Remove C:\Foo from the User path scope.
   Push-Path C:\Foo -Scope User
#>

Function Remove-Path {
    [CmdletBinding()]
    Param(
        [string[]] $Path,
        [System.EnvironmentVariableTarget] $Scope = 'Process'
    )
    process {
        if ($Scope -eq [System.EnvironmentVariableTarget]::Machine -and !(CheckAdmin)) {
            Write-Error "To remove for the system scope you have to run as admin!"
            return;
        }

        [System.Collections.ArrayList]$m_Path = (Get-Path -Scope $Scope)
        foreach ($m_sPath in $Path) {
            $idx = Find-Path -Scope $Scope -Path $m_sPath
            if (!$idx) { 
                Write-Warning "$m_sPath is not in the path... ignoring"
                continue
            }
            $m_Path.RemoveAt($idx)
        }
    }
}