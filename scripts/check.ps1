$ErrorActionPreference = "Stop"

$capstoneRoot = Split-Path -Parent $PSScriptRoot

Push-Location $capstoneRoot
try {
    terraform fmt -check -recursive
    if ($LASTEXITCODE -ne 0) {
        throw "terraform fmt check failed with exit code $LASTEXITCODE"
    }

    foreach ($terraformRoot in @("terraform/cluster", "terraform/bootstrap")) {
        terraform "-chdir=$terraformRoot" validate
        if ($LASTEXITCODE -ne 0) {
            throw "terraform validate failed for $terraformRoot with exit code $LASTEXITCODE"
        }
    }

    git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff check failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
