function Write-Error {
  param([string]$Error)

  $messages = @{
    ru = @{
      logFile = @(
        "Не удаётся найти лог-файл Genshin Impact!",
        "Не забудьте сначала открыть историю молитв в игре.",
        "Если вы продолжаете сталкиваться с этой проблемой, попробуйте запустить Powershell от имени администратора."
      )
      urlNotFound = @(
        "Извините, не удаётся найти нужную ссылку в лог-файле.",
        "Не забудьте сначала открыть историю молитв в игре.",
        "Если вы продолжаете сталкиваться с этой проблемой, попробуйте запустить Powershell от имени администратора."
      )
      unathorized = @(
        "Неверное значение куки 'remember-me'"
      )
      wrongUrl = @(
        "Недействительная ссылка в лог-файле.",
        "Откройте историю молитв в игре и попробуйте снова."
      )
      differentUid = @(
        "Вы пытаетесь импортировать молитвы из другого аккаунта!"
      )
      mihoyoUnreachable = @(
        "Не удаётся подключиться к серверу Genshin Impact.",
        "Повторите попытку позже."
      )
      newWishesDuringImport = @(
        "Извините, ваша история молитв изменилась во время импорта.",
        "Пожалуйста, попробуйте снова."
      )
      alreadyImporting = @(
        "Импорт ваших молитв в процессе, будьте терпеливы!"
      )
      unknownServerError = @(
        "Сервер вернул ошибку!",
        "Пожалуйста, попробуйте снова."
      )
    }
    en = {
      logFile = @(
        "Sorry, we cannot find Genshin Impact log file.",
        "Make sure to open the wish history ingame first.",
        "If you keep seeing this issue, try to run Powershell as administrator."
      )
      urlNotFound = @(
        "Sorry, we cannot find wish history URL in the log file.",
        "Make sure to open the wish history ingame first.",
        "If you keep seeing this issue, try to run Powershell as administrator."
      )
      unathorized = @(
        "Wrong 'remember-me' cookie value"
      )
      wrongUrl = @(
        "URL in the log file is wrong.",
        "Open the wish history ingame and try again."
      )
      differentUid = @(
        "You are trying to import wishes from another account!"
      )
      mihoyoUnreachable = @(
        "Unable to connect to Genshin Impact server.",
        "Please try again later."
      )
      newWishesDuringImport = @(
        "Sorry, your wish history changed during the import.",
        "Please try again."
      )
      alreadyImporting = @(
        "An import of your wishes is already occurring, please be patient!"
      )
      unknownServerError = @(
        "Server returned an error!",
        "Please try again."
      )
    }
  }

  $errorLines = $messages.$LANG.$Error
  if (-not $errorLines) { return }

  for ($i = 0; $i -lt $errorLines.Length; $i++) {
    $color = if ($i -eq 0) { "Red" } else { "Yellow" }
    Write-Host $errorLines[$i] -ForegroundColor $color
  }
}

function Handle-Error {
  param(
    [string]$Error,
    [string]$ErrorDetails = $null
  )

  Write-Error $Error

  switch ($Error) {
    'unathorized' {
      Get-Remember-Me-Cookie -Force
      Import
      exit
    }
    'serverError' {
      switch ($ErrorDetails) {
        'AUTHKEY_INVALID' {
          Write-Error 'wrongUrl'
          break
        }
        'MIHOYO_UID_DIFFERENT' {
          Write-Error 'differentUid'
          break
        }
        'MIHOYO_UNREACHABLE' {
          Write-Error 'mihoyoUnreachable'
          break
        }
        'NEW_WISHES_DURING_IMPORT' {
          Write-Error 'newWishesDuringImport'
          break
        }
        'ALREADY_IMPORTING' {
          Write-Error 'alreadyImporting'
          break
        }
        default {
          Write-Error 'unknownServerError'
        }
      }
    }
  }

  Enter-To-Exit
}

function Enter-To-Exit {
  if ($LANG -eq "ru") {
    Read-Host "Нажмите Enter чтобы выйти..."
  } else {
    Read-Host "Press Enter to exit..."
  }
  exit
}

function File-Path {
  $globalPath = [System.Environment]::ExpandEnvironmentVariables("%userprofile%\AppData\LocalLow\miHoYo\Genshin Impact\output_log.txt");
  $chinaPath = [System.Environment]::ExpandEnvironmentVariables("%userprofile%\AppData\LocalLow\miHoYo\$([char]0x539f)$([char]0x795e)\output_log.txt");
  $globalPathExist = [System.IO.File]::Exists($globalPath);
  $chinaPathExist = [System.IO.File]::Exists($chinaPath);

  if ($globalPathExist -xor $chinaPathExist) {
    if ($globalPathExist) {
      return $globalPath
    } else {
      return $chinaPath
    }
  } else {
    if ($globalPathExist -and $chinaPathExist) {
      if (((Get-ItemProperty -Path $chinaPath -Name LastWriteTime).lastwritetime - (Get-ItemProperty -Path $globalPath -Name LastWriteTime).lastwritetime) -gt 0) {
        return $chinaPath
      } else {
        return $globalPath
      }
    } else {
      Handle-Error "logFile"
      return
    }
  }
}

function Get-Link {
  param([string]$FilePath)

  $logs = Get-Content -Path $FilePath
  $match = $logs -match "^OnGetWebViewPageFinish:.+log$"
  if (-Not $match) {
    Handle-Error "urlNotFound"
    return
  }

  return $match[$match.count-1] -replace 'OnGetWebViewPageFinish:', ''
}

function Parse-Link {
  param([string]$Url)

  $match = $Url -match "authkey=([^\&\#]+)[\&\#]"
  if (-Not $match) {
    Handle-Error "urlNotFound"
    return
  }
  $authkey = [System.Web.HttpUtility]::UrlEncode($Matches[1])

  $match = $Url -match "game_biz=([^\&\#]+)[\&\#]"
  if (-Not $match) {
    Handle-Error "urlNotFound"
    return
  }
  $gameBiz = [System.Web.HttpUtility]::UrlEncode($Matches[1])

  return @{
    authkey = $authkey
    game_biz = $gameBiz
  }
}

function Parse-Response {
  param(
    [parameter(Mandatory, ParameterSetName="WithResponse", Position=0)][Microsoft.PowerShell.Commands.WebResponseObject]$Response,
    [parameter(Mandatory, ParameterSetName="WithBaseResponse", Position=0)][System.Net.HttpWebResponse]$BaseResponse
  )

  if ($Response) {
    $statusCode = $Response.StatusCode
    $content = $Response.Content
  } else {
    $statusCode = [int]$BaseResponse.StatusCode

    $stream = $BaseResponse.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $content = $reader.ReadToEnd()
  }

  switch ($statusCode) {
    200 {
      return ($content | ConvertFrom-Json)
    }
    401 {
      Handle-Error "unathorized"
      return $False
    }
    500 {
      $data = $content | ConvertFrom-Json
      Handle-Error "serverError" $data
      return $False
    }
    default {
      return $False
    }
  }
}

function Request-Import {
  param (
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
    [Hashtable]$AuthParams
  )

  $response = try {
    Invoke-WebRequest -WebSession $Session `
      -Uri "https://genshin-wishes.com/api/wishes/import?authkey=$($AuthParams.authkey)&game_biz=$($AuthParams.game_biz)"
  } catch {
    $_.Exception.Response
  }

  return (Parse-Response $response)
}

function Request-Import-State {
  param([Microsoft.PowerShell.Commands.WebRequestSession]$Session)

  $response = try {
    Invoke-WebRequest -WebSession $Session -Uri "https://genshin-wishes.com/api/wishes/importState"
  } catch {
    $_.Exception.Response
  }

  return (Parse-Response $response)
}

function Request-Import-Finish {
  param([Microsoft.PowerShell.Commands.WebRequestSession]$Session)

  $response = try {
    Invoke-WebRequest -WebSession $Session -Method Delete -Uri "https://genshin-wishes.com/api/wishes/importState" `
      -Headers @{
        "x-xsrf-token" = ($Session.Cookies.GetCookies("https://genshin-wishes.com") | where Name -eq "XSRF-TOKEN").value
      }
  } catch {
    $_.Exception.Response
  }

  return (Parse-Response $response)
}

function Print-Import-Result {
  param([PSCustomObject]$Data)

  $translation = @{
    ru = @{
      message = "Импортировано новых молитв:"
      WEAPON_EVENT = "Молитвы события оружия"
      CHARACTER_EVENT = "Молитвы события персонажа"
      PERMANENT = "Стандартные молитвы"
      NOVICE = "Молитвы новичка"
    }
    en = @{
      message = "New wishes imported:"
      WEAPON_EVENT = "Weapon banner"
      CHARACTER_EVENT = "Character banner"
      PERMANENT = "Permanent banner"
      NOVICE = "Novice banner"
    }
  }

  Write-Host $translation.$LANG.message -ForegroundColor Green
  foreach ($banner in $Data.PsObject.Properties) {
    $bannerType = $banner.Value.bannerType
    $count = $banner.Value.count
    Write-Host "$($translation.$LANG.$bannerType) - $($count)" -ForegroundColor Yellow
  }
}

function Do-Import {
  param(
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
    [Hashtable]$AuthData
  )

  Request-Import $Session -AuthParams $AuthData
  $state = Request-Import-State $Session
  while (-not $state.WEAPON_EVENT.saved -or -not $state.CHARACTER_EVENT.saved -or -not $state.PERMANENT.saved -or -not $state.NOVICE.saved) {
    Write-Host "." -NoNewline
    if ($state.WEAPON_EVENT.error -or $state.CHARACTER_EVENT.error -or $state.PERMANENT.error -or $state.NOVICE.error) {
      return (Do-Import $Session, $AuthData)
    }
    $state = Request-Import-State $Session
    Start-Sleep -Seconds 1
  }

  Write-Host
  Request-Import-Finish $Session
  return $state
}

function Get-Remember-Me-Cookie {
  param([switch]$Force)

  $fileName = "genshin-wishes-remember-me-cookie.txt"

  if (Test-Path $fileName) {
    $path = Resolve-Path $fileName
  }

  if ($path) {
    $data = Get-Content -Path $path
    if (-not $Force -and $data) {
      return $data
    }
    else {
      Remove-Item -Path $path
    }
  }

  $cookie = if ($LANG -eq "ru") {
    Read-Host "Введите значение куки 'remember-me' с сайта https://genshin-wishes.com"
  } else {
    Read-Host "Please enter the 'remember-me' cookie value from https://genshin-wishes.com site"
  }

  $null = New-Item -Path . -Name $fileName -ItemType "file" -Value $cookie
  return $cookie
}

function Import {
  $rememberMe = Get-Remember-Me-Cookie
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.Cookies.Add((New-Object System.Net.Cookie("remember-me", $rememberMe, "/", "genshin-wishes.com")))

  $filePath = File-Path
  $url = Get-Link $filePath
  $authData = Parse-Link $url
  $result = Do-Import -Session $session -AuthData $authData
  Print-Import-Result $result
  Enter-To-Exit
}

Add-Type -AssemblyName System.Web
if ((Get-Culture).Name -eq "ru-RU") { $LANG = "ru" } else { $LANG = "en" }
Import
