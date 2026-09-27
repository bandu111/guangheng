$ErrorActionPreference = 'Stop'
$docx = 'C:\Users\bandu\Desktop\黑客松比赛材料\光衡_GuangHeng_Anker黑客松预赛提交材料.docx'
$pdf = 'C:\Users\bandu\Desktop\黑客松比赛材料\光衡_GuangHeng_Anker黑客松预赛提交材料.pdf'
$tempDocx = 'D:\flutterProject\guangheng\tools\submission\guangheng_submission.docx'
$tempPdf = 'D:\flutterProject\guangheng\tools\submission\guangheng_submission.pdf'
Copy-Item -LiteralPath $docx -Destination $tempDocx -Force
$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
    $document = $word.Documents.Open($tempDocx, $false, $true)
    $document.ExportAsFixedFormat($tempPdf, 17)
    $document.Close($false)
} finally {
    try { $word.Quit() } catch { }
}
Copy-Item -LiteralPath $tempPdf -Destination $pdf -Force
Get-Item -LiteralPath $pdf | Select-Object FullName,Length,LastWriteTime
