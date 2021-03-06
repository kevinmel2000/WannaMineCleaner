write-output "" | out-file "failed.txt"
foreach($ip in Get-Content .\serverlist.txt) {
  Write-Output "===================================" 
  Write-Output "Processing $ip ..." 
  
  gwmi win32_bios -ComputerName $ip -ErrorAction SilentlyContinue -ErrorVariable err

  if ($err) {
    $msg = $Error[0].Exception.Message
    write-output "$ip # $msg" | out-file -append "failed.txt"
    continue
  }
  
  Write-Host "Connection on computer $ip successful." -ForegroundColor DarkGreen

  #these lines are used to kill malicious process which can be identified by their command line or path
  wmic /node:$ip process WHERE "COMMANDLINE LIKE '%default:Win32_Services%'" CALL TERMINATE
  wmic /node:$ip process WHERE "COMMANDLINE LIKE '%info6.ps1%'" CALL TERMINATE
  wmic /node:$ip process WHERE "ExecutablePath='C:\\ProgramData\\UpdateService\\UpdateService.exe'" CALL TERMINATE
  wmic /node:$ip process WHERE "ExecutablePath='C:\\ProgramData\\AppCache\\18\\java.exe'" CALL TERMINATE
  wmic /node:$ip process WHERE "ExecutablePath='C:\\ProgramData\\AppCache\\17_\\java.exe'" CALL TERMINATE
  wmic /node:$ip process WHERE "ExecutablePath='C:\\ProgramData\\AppCache\\17\\java.exe'" CALL TERMINATE
  wmic /node:$ip process WHERE "ExecutablePath='C:\\ProgramData\\AppCache\\16\\java.exe'" CALL TERMINATE
  wmic /node:$ip process WHERE "COMMANDLINE LIKE '%JABzAHQAaQBtAGUAPQBbAEUAbgB2AGkAcgBvAG4AbQBlAG4AdABdADoAOgBUAG%'" CALL TERMINATE

  #delete all malicious files
  WMIC /node:$ip path cim_datafile WHERE "path='C:\\ProgramData\\UpdateService\\UpdateService.exe'" delete
  WMIC /node:$ip path cim_datafile WHERE "path='C:\\ProgramData\\AppCache\\17_\\java.exe'" delete
  WMIC /node:$ip path cim_datafile WHERE "path='C:\\ProgramData\\AppCache\\17\\java.exe'" delete
  WMIC /node:$ip path cim_datafile WHERE "path='C:\\ProgramData\\AppCache\\16\\java.exe'" delete
  WMIC /node:$ip path cim_datafile WHERE "path='C:\\ProgramData\\AppCache\\18\\java.exe'" delete

  #change "Win32_Services" and "DSM Event" to match evil class and instance name found in your environment
  wmic /node:$ip /NAMESPACE:"\\root\default" Class Win32_Services DELETE
  wmic /node:$ip /NAMESPACE:"\\root\subscription" PATH __EventFilter WHERE "Name LIKE 'DSM Event%'" DELETE
  wmic /node:$ip /NAMESPACE:"\\root\subscription" PATH CommandLineEventConsumer WHERE "Name LIKE 'DSM Event%'" DELETE
  wmic /node:$ip /NAMESPACE:"\\root\subscription" PATH __FilterToConsumerBinding WHERE "Filter=""__EventFilter.Name='DSM Event Log Filter'""" DELETE
  wmic /node:$ip /NAMESPACE:"\\root\subscription" PATH __FilterToConsumerBinding WHERE "Filter=""__EventFilter.Name='DSM Event Logs Filter'""" DELETE
}
