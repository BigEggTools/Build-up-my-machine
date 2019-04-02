
function Get-MachineArchitecture {
    Write-Host "THe architecture of this machine is: $ENV:PROCESSOR_ARCHITECTURE"

    # possible values: AMD64, X64, X86, ARM64, ARM
    switch ($ENV:PROCESSOR_ARCHITECTURE) {
        "AMD64" {
            return "64"
        }
        "x64" {
            return "64"
        }
        Default {
            return "32"
        }
    }
}
