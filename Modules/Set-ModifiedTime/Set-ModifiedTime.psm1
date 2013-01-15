#----------------------------------------------------------------
# Set-ModifiedTime.ps1
#----------------------------------------------------------------
param
(
  [string]$filespec = $null,         # Files to touch
  [DateTime]$datetime = ([DateTime]::Now), # Use DateTime STRING instead of current time.
  [int]$forward = 0,                 # Modify the time by going forward SECONDS s.
  [string]$reference = $null,        # Use this file's time instead of current time.
  [bool]$only_modification = $false, # Change only the modification time.
  [bool]$only_access = $false        # Change only the access time
);

#----------------------------------------------------------------
# Function Set-ModifiedTime
#----------------------------------------------------------------
function Set-ModifiedTime {
  param(
    [string]$filespec = $null,
    [datetime]$datetime = ([DateTime]::Now),
    [int]$forward = 0,
    [string]$reference = $null,
    [bool]$only_modification = $false,
    [bool]$only_access = $false
  );
  
  $touch = $null;
  
  if ( $filespec )
  {
    $files = @(Get-ChildItem -Path $filespec -ErrorAction SilentlyContinue)
    if ( !$files )
    {
      # If file doesn't exist, attempt to create one.
      # A wildcard patter will fail silently.
      Set-Content -Path $filespec -value $null;
      $files = @(Get-ChildItem -Path $filespec -ErrorAction SilentlyContinue);
    }
    
    if ( $files )
    {
      if ( $reference )
      {
        $reffile = Get-ChildItem -Path $reference -ErrorAction SilentlyContinue;
        if ( $reffile )
        {
          [datetime]$touch = $reffile.LastAccessTime.AddSeconds($forward);
        }
      }
      elseif ( $datetime )
      {
        [datetime]$touch = $datetime.AddSeconds($forward);
      }
      
      if ( $touch )
      {
        [DateTime]$UTCTime = $touch.ToUniversalTime();
        foreach ($file in $files)
        {
          if ( $only_access )
          {
            $file.LastAccessTime=$touch
            $file.LastAccessTimeUtc=$UTCTime
          }
          elseif ( $only_modification )
          {
            $file.LastWriteTime=$touch
            $file.LastWriteTimeUtc=$UTCTime
          }
          else
          {
            $file.CreationTime = $touch;
            $file.CreationTimeUtc = $UTCTime;
            $file.LastAccessTime=$touch
            $file.LastAccessTimeUtc=$UTCTime
            $file.LastWriteTime=$touch
            $file.LastWriteTimeUtc=$UTCTime
          }
          $file | select Name, *time*
        }
      }
    }
  }
}

