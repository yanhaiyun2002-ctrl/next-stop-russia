$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime] | Out-Null
[Windows.Media.Editing.MediaClip, Windows.Media.Editing, ContentType=WindowsRuntime] | Out-Null
[Windows.Media.Editing.MediaComposition, Windows.Media.Editing, ContentType=WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.ImageStream, Windows.Graphics.Imaging, ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.FileProperties.VideoProperties, Windows.Storage.FileProperties, ContentType=WindowsRuntime] | Out-Null
$taskAwaitMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 } | Select-Object -First 1
function Wait-TaskVideo($Operation, [type]$ResultType) {
    $taskAwaiter = $taskAwaitMethod.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $taskAwaiter.GetAwaiter().GetResult()
}
$taskInput = [IO.Path]::GetFullPath('docs/references/dorm_visual_reference.mp4')
$taskFile = Wait-TaskVideo ([Windows.Storage.StorageFile]::GetFileFromPathAsync($taskInput)) ([Windows.Storage.StorageFile])
$taskProps = Wait-TaskVideo ($taskFile.Properties.GetVideoPropertiesAsync()) ([Windows.Storage.FileProperties.VideoProperties])
$taskClip = Wait-TaskVideo ([Windows.Media.Editing.MediaClip]::CreateFromFileAsync($taskFile)) ([Windows.Media.Editing.MediaClip])
$taskComposition = New-Object Windows.Media.Editing.MediaComposition
[System.Collections.Generic.ICollection[Windows.Media.Editing.MediaClip]].GetMethod('Add').Invoke($taskComposition.Clips, @($taskClip))
$taskInfo = [ordered]@{ duration_seconds=$taskProps.Duration.TotalSeconds; width=$taskProps.Width; height=$taskProps.Height; frame_rate_milli=$taskProps.FrameRate; decoder='Windows MediaComposition / nearest-frame request' }
$taskInfo | ConvertTo-Json | Set-Content -Encoding utf8 docs/evidence/p0-03r/video_info_reextracted.json
$taskInfo | ConvertTo-Json
New-Item -ItemType Directory -Force docs/evidence/p0-03r/reference_frames | Out-Null
foreach ($taskSecond in @(0,1,2,3,10,15,18,20,24,28,32,34,36,38,40,42,44,45,46,48,50,52,54,56,58,60,62,63)) {
    if ($taskSecond -ge $taskProps.Duration.TotalSeconds) { continue }
    $taskThumbnail = Wait-TaskVideo ($taskComposition.GetThumbnailAsync([TimeSpan]::FromSeconds($taskSecond), 512, 0, [Windows.Media.Editing.VideoFramePrecision]::NearestFrame)) ([Windows.Graphics.Imaging.ImageStream])
    $taskStream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($taskThumbnail)
    $taskOutput = [IO.File]::Create([IO.Path]::GetFullPath(('docs/evidence/p0-03r/reference_frames/frame_{0:000}.jpg' -f $taskSecond)))
    $taskStream.CopyTo($taskOutput)
    $taskOutput.Dispose()
    $taskStream.Dispose()
    Write-Output ('FRAME_SECONDS='+$taskSecond)
}



