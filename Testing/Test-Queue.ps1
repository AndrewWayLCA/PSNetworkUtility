$latency = [System.Collections.Generic.Queue[int]]::new()

$latency.Enqueue(20)
$latency.Enqueue(60)
$latency.Enqueue(40)

$latency.Count

$maxL = $latency | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

$maxL