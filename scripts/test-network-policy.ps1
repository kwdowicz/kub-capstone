$ErrorActionPreference = "Stop"

$capstoneRoot = Split-Path -Parent $PSScriptRoot
$env:KUBECONFIG = Join-Path $capstoneRoot ".local\kubeconfig"
$testRoot = Join-Path $capstoneRoot "tests\network-policy"

function Invoke-Kubectl {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$KubectlArgs)

    & kubectl @KubectlArgs
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl failed with exit code ${LASTEXITCODE}: $($KubectlArgs -join ' ')"
    }
}

try {
    Invoke-Kubectl apply -f (Join-Path $testRoot "base.yaml")
    Invoke-Kubectl rollout status deployment/server -n policy-smoke --timeout=120s
    Invoke-Kubectl wait --for=condition=Ready pod/client -n policy-smoke --timeout=120s

    Invoke-Kubectl exec -n policy-smoke client "--" wget -qO- -T 3 http://server:8080/

    Invoke-Kubectl apply -f (Join-Path $testRoot "deny.yaml")

    $denied = $false
    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & kubectl exec -n policy-smoke client "--" wget -qO- -T 2 http://server:8080/ 2>$null
        $probeExitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousErrorActionPreference
        if ($probeExitCode -ne 0) {
            $denied = $true
            break
        }
        Start-Sleep -Seconds 1
    }
    if (-not $denied) {
        throw "NetworkPolicy default-deny did not block the client"
    }

    Invoke-Kubectl apply -f (Join-Path $testRoot "allow.yaml")

    $allowed = $false
    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        & kubectl exec -n policy-smoke client "--" wget -qO- -T 2 http://server:8080/
        if ($LASTEXITCODE -eq 0) {
            $allowed = $true
            break
        }
        Start-Sleep -Seconds 1
    }
    if (-not $allowed) {
        throw "Explicit allow policy did not restore client connectivity"
    }

    Write-Output "NetworkPolicyTest=PASS"
}
finally {
    & kubectl delete namespace policy-smoke --ignore-not-found --wait=true --timeout=120s
}
