# new ping command for PowerShell that uses a bit of character graphics
function Write-PingResult {
    param ([string]$ComputerName, [int]$ResponseTime, [int]$MaxResponseTime)

    $MaxResponseAsText = $MaxResponseTime.ToString() + "ms"
    $ResponseTimeAsText = $ResponseTime.ToString() + "ms"
    $SuffixCharacters = 0

    $AvailableWidth = $Host.UI.RawUI.WindowSize.Width

    $AvailableWidth -= $ComputerName.Length
    $AvailableWidth -= $MaxResponseAsText.Length

    $AvailableWidth -= 7 # padding and brackets

    $ResponseCharacters = [int][math]::Truncate($AvailableWidth / $MaxResponseTime * $ResponseTime)

    if ($ResponseCharacters + $ResponseTimeAsText.Length -gt $AvailableWidth) {

        $ResponseCharacters = $AvailableWidth - $ResponseTimeAsText.Length
        $SuffixCharacters = 0
    }
    else {
        $SuffixCharacters = $AvailableWidth - $ResponseCharacters - $ResponseTimeAsText.Length
    }

    $OutputLine = ''

    if ($ResponseCharacters -lt 0 -or $SuffixCharacters -lt 0) {
        $OutputLine = $ComputerName + ": " + $ResponseTimeAsText
    }
    else {
        $OutputLine = $ComputerName + ": [" + "=" * $ResponseCharacters + " " + $ResponseTimeAsText + " " +
        "_" * $SuffixCharacters + "] " + $MaxResponseAsText
    }
    
    Write-Host $OutputLine
}
function Write-PingError {
    param ([string]$ComputerName, [string]$ErrorMessage)

    Write-Host "${ComputerName}: $ErrorMessage" -ForegroundColor Yellow
}

$_latencyQueue = [System.Collections.Generic.Queue[int]]::new()

function Update-MaximumLatencyInQueue {
    <#
    .SYNOPSIS
        Takes the new latency figure and puts it onto the queue, removing the oldest value if the queue is full.
    .DESCRIPTION
        Takes the new latency figure and puts it onto the queue, removing the oldest value if the queue is full.
    .NOTES
        This has the effect of making sure the "maximum" latency updates as more pings are returned.
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    
    [OutputType([int])]
    param(
        [Parameter(Mandatory)][int]$ResponseTime
    )

    $latencyRounding = 50

    # add a new latency to the queue until it's full then remove the oldest
    $_latencyQueue.Enqueue($ResponseTime)
    if ($_latencyQueue.Count -gt $Host.UI.RawUI.WindowSize.Height) {
        $_latencyQueue.Dequeue() | Out-Null
    }

    # gets the maximum latency from the list [# of lines] ping results
    $maxLatency = $_latencyQueue | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

    # round latency to the nearest 100ms
    $maxLatency = ([int][math]::Truncate(($maxLatency / $latencyRounding)) + 1) * $latencyRounding
    return $maxLatency
}

function Test-Ping {
    [Alias("ping")]
    param (
        [Parameter(Mandatory)][string]$ComputerName,
        [ValidateNotNullOrEmpty()][int]$DelayMilliseconds = 1000,
        [ValidateNotNullOrEmpty()][int]$BufferSize = 32
    )

    $title = "Pinging {0} each {1}ms with {2} bytes of data:" -f $ComputerName, $DelayMilliseconds, $BufferSize
    Write-Host $title

    do {
    
        $pingResponse = Test-Connection -TargetName $ComputerName -Count 1 -BufferSize $BufferSize -TimeoutSeconds 1

        if ($pingResponse.Status -eq "Success" ) {

            $MaxResponseTime = Update-MaximumLatencyInQueue -ResponseTime $pingResponse.Latency
            Write-PingResult -ComputerName $pingResponse.Address -ResponseTime $pingResponse.Latency -MaxResponseTime $MaxResponseTime

        } else {
            Write-PingError -ComputerName $ComputerName -ErrorMessage $pingResponse.Status
        }
    
        #TODO: I don't think this works :-( update code so that any keypress stops the loop
        if ([console]::KeyAvailable) {
            $key = [system.console]::ReadKey($true)
            if (($key.modifiers -band [System.ConsoleModifiers]"control") -and ($key.Key -eq "C")) {
                "Exiting..."
                break
            }
        }

        Start-Sleep -Milliseconds $DelayMilliseconds

    } while ($true)

}

Export-ModuleMember -Alias ping
