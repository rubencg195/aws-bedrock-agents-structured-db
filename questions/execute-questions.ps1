# Simple PowerShell script to execute questions via Lambda and save results
$questionsPath = Join-Path $PSScriptRoot "questions.json"
$questions = Get-Content $questionsPath | ConvertFrom-Json
$resultsPath = Join-Path $PSScriptRoot "results.txt"

Write-Host "Starting execution of $($questions.Count) questions..." -ForegroundColor Green

# Check if results file exists and has content
if (Test-Path $resultsPath) {
    $existingContent = Get-Content $resultsPath
    if ($existingContent.Count -gt 0) {
        Write-Host "Found existing results file with $($existingContent.Count) lines. Continuing from where we left off..." -ForegroundColor Yellow
        # Find the last completed question number
        $lastQuestion = 0
        foreach ($line in $existingContent) {
            if ($line -match "^Question (\d+):") {
                $lastQuestion = [int]$Matches[1]
            }
        }
        Write-Host "Last completed question: $lastQuestion. Starting from question $($lastQuestion + 1)..." -ForegroundColor Yellow
        
        # Filter questions to only process remaining ones
        $questions = $questions | Where-Object { $_.id -gt $lastQuestion }
        Write-Host "Remaining questions to process: $($questions.Count)" -ForegroundColor Green
    }
}

foreach ($question in $questions) {
    Write-Host "Processing Question $($question.id): $($question.question)" -ForegroundColor Yellow
    
    $payload = '{"question": "' + $question.question + '"}'
    
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while ($retryCount -lt $maxRetries -and -not $success) {
        $retryCount++
        $attemptText = if ($retryCount -eq 1) { "Initial attempt" } else { "Retry attempt $($retryCount - 1)" }
        
        Write-Host "  $attemptText ($retryCount/$maxRetries)" -ForegroundColor Cyan
        
        try {
            $startTime = Get-Date
            
            $payloadFile = [System.IO.Path]::GetTempFileName()
            $responseFile = [System.IO.Path]::GetTempFileName()
            
            # Convert payload to base64
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
            $base64Payload = [System.Convert]::ToBase64String($bytes)
            
            $base64Payload | Set-Content $payloadFile
            
            Write-Host "    Invoking Lambda with payload: $payload" -ForegroundColor Gray
            
            $lambdaResult = aws lambda invoke `
                --function-name "mcp-demo-bedrock-invoke" `
                --payload $base64Payload `
                --region us-east-1 `
                $responseFile 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "Lambda invocation failed: $lambdaResult"
            }
            
            Write-Host "    Lambda invocation successful" -ForegroundColor Gray
            
            $responseContent = Get-Content $responseFile | ConvertFrom-Json
            
            Write-Host "    Raw response content: $($responseContent | ConvertTo-Json)" -ForegroundColor Gray
            
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalMilliseconds
            
            # Parse the response - Lambda returns the result in the Payload field
            if ($responseContent.Payload) {
                Write-Host "    Found Payload field, parsing..." -ForegroundColor Gray
                $responseData = $responseContent.Payload | ConvertFrom-Json
                Write-Host "    Parsed response data: $($responseData | ConvertTo-Json)" -ForegroundColor Gray
            } else {
                Write-Host "    No Payload field, using raw content" -ForegroundColor Gray
                $responseData = $responseContent
            }
            
            # Parse the body field which contains the actual response
            if ($responseData.body) {
                Write-Host "    Found body field, parsing..." -ForegroundColor Gray
                $bodyData = $responseData.body | ConvertFrom-Json
                Write-Host "    Parsed body data: $($bodyData | ConvertTo-Json)" -ForegroundColor Gray
                
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
                Write-Host "    No body field found" -ForegroundColor Gray
                $llmAnswer = "No response data"
                $llmQuery = "No query data"
            }
            
            # Don't delete files yet for debugging
            Write-Host "    Response file contents: $(Get-Content $responseFile)" -ForegroundColor Gray
            
            # Write results to file
            "Question $($question.id): $($question.question)" | Add-Content $resultsPath
            "LLM-Answer: $llmAnswer" | Add-Content $resultsPath
            "LLM-Query: $llmQuery" | Add-Content $resultsPath
            "LLM-Execution-Time: $([math]::Round($executionTime, 2))ms" | Add-Content $resultsPath
            "" | Add-Content $resultsPath
            
            Write-Host "    Completed in $([math]::Round($executionTime, 2))ms" -ForegroundColor Green
            $success = $true
            
            # Clean up files
            Remove-Item $payloadFile
            Remove-Item $responseFile
            
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Host "    Error on attempt $retryCount`: $errorMsg" -ForegroundColor Red
            
            if ($retryCount -eq $maxRetries) {
                Write-Host "    All retry attempts failed for question $($question.id)" -ForegroundColor Red
                
                # Write final error to file
                "Question $($question.id): $($question.question)" | Add-Content $resultsPath
                "LLM-Answer: ERROR: $errorMsg (after $maxRetries attempts)" | Add-Content $resultsPath
                "LLM-Query: ERROR: $errorMsg (after $maxRetries attempts)" | Add-Content $resultsPath
                "LLM-Execution-Time: 0ms" | Add-Content $resultsPath
                "" | Add-Content $resultsPath
            } else {
                Write-Host "    Retrying in 3 seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
            
            # Clean up files on error
            if (Test-Path $payloadFile) { Remove-Item $payloadFile }
            if (Test-Path $responseFile) { Remove-Item $responseFile }
        }
    }
    
    Start-Sleep -Seconds 2
}

Write-Host "Execution completed! Results saved to: $resultsPath" -ForegroundColor Green
