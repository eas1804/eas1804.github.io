$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:3000/")
$listener.Start()
Write-Host "HTTP server runing in tcp 3000..."

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $response = $context.Response

    $html = "<html><body><h1>Hello from PowerShell HTTP Server</h1></body></html>"
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)

    $response.ContentLength64 = $buffer.Length
    $response.ContentType = "text/html"
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}