# Test script for single question
$question = @{
    id = 1
    question = "How many assets are located in FMX High School?"
}

Write-Host "Testing Question $($question.id): $($question.question)" -ForegroundColor Yellow

$payload = '{"question": "' + $question.question + '"}'

try {
    $startTime = Get-Date
    
    $payloadFile = [System.IO.Path]::GetTempFileName()
    $responseFile = [System.IO.Path]::GetTempFileName()
    
    # Convert payload to base64
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $base64Payload = [System.Convert]::ToBase64String($bytes)
    
    Write-Host "  Invoking Lambda with payload: $payload" -ForegroundColor Gray
    
    $lambdaResult = aws lambda invoke `
        --function-name "mcp-demo-bedrock-invoke" `
        --payload $base64Payload `
        --region us-east-1 `
        $responseFile 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "Lambda invocation failed: $lambdaResult"
    }
    
    Write-Host "  Lambda invocation successful" -ForegroundColor Gray
    
    $responseContent = Get-Content $responseFile | ConvertFrom-Json
    
    Write-Host "  Raw response content: $($responseContent | ConvertTo-Json)" -ForegroundColor Gray
    
    $endTime = Get-Date
    $executionTime = ($endTime - $startTime).TotalMilliseconds
    
    # Parse the response - Lambda returns the result in the Payload field
    if ($responseContent.Payload) {
        Write-Host "  Found Payload field, parsing..." -ForegroundColor Gray
        $responseData = $responseContent.Payload | ConvertFrom-Json
        Write-Host "  Parsed response data: $($responseData | ConvertTo-Json)" -ForegroundColor Gray
    } else {
        Write-Host "  No Payload field, using raw content" -ForegroundColor Gray
        $responseData = $responseContent
    }
    
    # Parse the body field which contains the actual response
    if ($responseData.body) {
        Write-Host "  Found body field, parsing..." -ForegroundColor Gray
        $bodyData = $responseData.body | ConvertFrom-Json
        Write-Host "  Parsed body data: $($bodyData | ConvertTo-Json)" -ForegroundColor Gray
        
        # Extract the LLM response data
        $llmQuery = $bodyData.sql_query
        
        # Extract and format the results
        if ($bodyData.results -and $bodyData.results.Count -gt 0) {
            # Convert results to readable format
            $llmAnswer = ($bodyData.results | ConvertTo-Json -Compress)
        } else {
            $llmAnswer = "No results found (empty array)"
        }
    } else {
        Write-Host "  No body field found" -ForegroundColor Gray
        $llmAnswer = "No response data"
        $llmQuery = "No query data"
    }
    
    Write-Host "  LLM Answer: $llmAnswer" -ForegroundColor Green
    Write-Host "  LLM Query: $llmQuery" -ForegroundColor Green
    Write-Host "  Execution Time: $([math]::Round($executionTime, 2))ms" -ForegroundColor Green
    
    # Clean up files
    Remove-Item $payloadFile
    Remove-Item $responseFile
    
} catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}
