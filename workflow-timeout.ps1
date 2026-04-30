function Invoke-WithTimeout {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$ScriptBlock,
    [Parameter(Mandatory = $true)]
    [string]$Activity,
    [int]$TimeoutSeconds = 600,
    [object[]]$ArgumentList = @()
  )

  $helperPath = Join-Path $env:GITHUB_WORKSPACE 'workflow-timeout.ps1'
  $job = Start-Job -ScriptBlock {
    param($HelperPath, $InnerScriptBlock, $InnerArgs)
    . $HelperPath
    & $InnerScriptBlock @InnerArgs
  } -ArgumentList $helperPath, $ScriptBlock, $ArgumentList
  try {
    if (Wait-Job -Job $job -Timeout $TimeoutSeconds) {
      $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
      if ($job.State -eq 'Failed') {
        throw "${Activity} failed"
      }
      return $result
    }

    Stop-Job -Job $job -Force -ErrorAction SilentlyContinue
    throw "${Activity} timed out after ${TimeoutSeconds}s"
  } finally {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-NativeChecked {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$ScriptBlock
  )

  & $ScriptBlock
  if ($LASTEXITCODE -ne 0) {
    throw "Native command failed with exit code $LASTEXITCODE"
  }
}
