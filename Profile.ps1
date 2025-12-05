# 0. Config Emacs mode Editing & installing [Oh-my-Posh](https://ohmyposh.dev/docs/installation/windows)
#==========================================================================================
Set-PSReadLineOption -EditMode Emacs
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\quick-term.omp.json" | Invoke-Expression


# ============================================
# CONFIGURACIÓN VIRTUALENVWRAPPER - VERSIÓN COMPLETA
# ============================================

# 1. Configurar la ruta base
$env:WORKON_HOME = "C:\Users\[your-user]\virtualenvs"

# 2. Crear directorio si no existe
if (-not (Test-Path $env:WORKON_HOME)) {
    New-Item -ItemType Directory -Path $env:WORKON_HOME -Force | Out-Null
    Write-Host "Directorio creado: $env:WORKON_HOME" -ForegroundColor Green
}

# 3. Remover módulo previo
Remove-Module VirtualEnvWrapper -ErrorAction SilentlyContinue
Remove-Item Function:Workon -ErrorAction SilentlyContinue
Remove-Item Function:Get-VirtualEnvs -ErrorAction SilentlyContinue

# 4. Cargar el módulo original
Import-Module VirtualEnvWrapper

# la función workon re-escrita hacia línea 349/235

# 6. Sobrescribir también Get-VirtualEnvs para consistencia
function Global:Get-VirtualEnvs {
    Write-Host "`nEntornos Virtuales disponibles:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    if (Test-Path $env:WORKON_HOME) {
        $envs = Get-ChildItem $env:WORKON_HOME -Directory
        if ($envs.Count -gt 0) {
            foreach ($env in $envs) {
                $pythonExe = "$($env.FullName)\Scripts\python.exe"
                if (Test-Path $pythonExe) {
                    try {
                        $version = (& $pythonExe --version 2>&1) -replace "Python ", ""
                        Write-Host "  $($env.Name) (Python $version)" -ForegroundColor Green
                    } catch {
                        Write-Host "  $($env.Name) [Versión desconocida]" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "  $($env.Name) [Sin Python]" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "  No hay entornos virtuales creados" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Directorio no encontrado: $env:WORKON_HOME" -ForegroundColor Red
    }
    Write-Host ""
}

# 7. Crear alias para compatibilidad
Set-Alias -Name lsvirtualenv -Value Get-VirtualEnvs -Scope Global -Force

# 8. Función de ayuda para ver el estado actual
function Global:Get-VenvStatus {
    Write-Host "`n=== ESTADO DE VIRTUALENVWRAPPER ===" -ForegroundColor Cyan
    
    # WORKON_HOME
    Write-Host "WORKON_HOME: $env:WORKON_HOME" -ForegroundColor White
    Write-Host "Existe: $(if (Test-Path $env:WORKON_HOME) {'Sí'} else {'No'})"
    
    # Entorno actual
    if ($env:VIRTUAL_ENV) {
        Write-Host "`nEntorno ACTUAL activado:" -ForegroundColor Green
        Write-Host "  Nombre: $(Split-Path $env:VIRTUAL_ENV -Leaf)"
        Write-Host "  Ruta: $env:VIRTUAL_ENV"
        
        # Verificar Python
        $pythonExe = "$env:VIRTUAL_ENV\Scripts\python.exe"
        if (Test-Path $pythonExe) {
            $version = & $pythonExe --version 2>&1
            Write-Host "  Python: $version"
        }
    } else {
        Write-Host "`nNo hay entorno virtual activado" -ForegroundColor Yellow
    }
    
    # Contar entornos
    if (Test-Path $env:WORKON_HOME) {
        $count = (Get-ChildItem $env:WORKON_HOME -Directory).Count
        Write-Host "`nTotal de entornos: $count"
    }
    
    Write-Host "`nComandos disponibles:" -ForegroundColor Cyan
    Write-Host "  workon <nombre>      - Activar entorno"
    Write-Host "  workon -List         - Listar entornos"
    Write-Host "  lsvirtualenv         - Listar entornos con detalles"
    Write-Host "  mkvirtualenv <nombre> - Crear nuevo entorno"
    Write-Host "  rmvirtualenv <nombre> - Eliminar entorno"
    Write-Host "  Get-VenvStatus       - Ver esta información"
    Write-Host "===============================`n" -ForegroundColor Cyan
}

# 9. Mensaje inicial
Write-Host "`n✓ VirtualEnvWrapper configurado" -ForegroundColor Green
Write-Host "  Directorio: $env:WORKON_HOME`n" -ForegroundColor Gray

# 10. Mostrar estado inicial
Get-VenvStatus


# ============================================
# INTEGRACIÓN OH-MY-POSH (quick-term) + VIRTUALENV
# ============================================

function Initialize-OhMyPosh {
    param([switch]$Force)
    
    Write-Host "`n🔄 Inicializando oh-my-posh..." -ForegroundColor Cyan
    
    # Verificar si oh-my-posh está instalado
    $ohMyPoshCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    
    if (-not $ohMyPoshCmd) {
        Write-Host "✗ oh-my-posh no encontrado" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✓ oh-my-posh encontrado" -ForegroundColor Green
    
    # CORREGIDO: Usar Join-Path para evitar problemas con barras
    $searchPaths = @()
    
    # 1. POSH_THEMES_PATH (limpio)
    if ($env:POSH_THEMES_PATH) {
        $cleanThemesPath = $env:POSH_THEMES_PATH.TrimEnd('\')
        $searchPaths += Join-Path $cleanThemesPath "quick-term.omp.json"
    }
    
    # 2. Rutas alternativas
    $commonPaths = @(
        "$env:USERPROFILE\.config\powershell",
        "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes",
        "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
    )
    
    foreach ($path in $commonPaths) {
        $searchPaths += Join-Path $path "quick-term.omp.json"
    }
    
    # Buscar theme
    $themePath = $null
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $themePath = $path
            Write-Host "✓ Theme encontrado: $themePath" -ForegroundColor Green
            break
        }
    }
    
    if (-not $themePath) {
        Write-Host "⚠ 'quick-term.omp.json' no encontrado" -ForegroundColor Yellow
        
        # Listar themes disponibles
        if ($env:POSH_THEMES_PATH -and (Test-Path $env:POSH_THEMES_PATH)) {
            $themes = Get-ChildItem "$env:POSH_THEMES_PATH\*.omp.json" -ErrorAction SilentlyContinue
            if ($themes) {
                Write-Host "Themes disponibles:" -ForegroundColor Cyan
                foreach ($theme in $themes) {
                    Write-Host "  - $($theme.Name)" -ForegroundColor Gray
                }
                
                # Preguntar al usuario o usar el primero
                $themePath = $themes[0].FullName
                Write-Host "Usando: $($themes[0].Name)" -ForegroundColor Yellow
            }
        }
    }
    
    if ($themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
        $global:OriginalPrompt = $function:prompt
        Write-Host "✓ oh-my-posh inicializado`n" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ No se pudo inicializar oh-my-posh`n" -ForegroundColor Red
        return $false
    }
}

# Función para crear prompt híbrido (virtualenv + oh-my-posh)
function Set-HybridPrompt {
    if (-not $global:OriginalPrompt) {
        # Inicializar oh-my-posh primero
        Initialize-OhMyPosh -Force
    }
    
    if ($global:OriginalPrompt) {
        # Crear prompt que muestra virtualenv y luego oh-my-posh
        function global:prompt {
            $realLASTEXITCODE = $LASTEXITCODE
            
            # 1. Mostrar entorno virtual (si existe) - estilo minimalista
            if ($env:VIRTUAL_ENV) {
                $envName = Split-Path $env:VIRTUAL_ENV -Leaf
                # Color que combine con quick-term (cyan/azul claro)
                Write-Host "($envName) " -NoNewline -ForegroundColor Cyan
            }
            
            # 2. Ejecutar el prompt original de oh-my-posh
            $promptResult = & $global:OriginalPrompt
            
            $global:LASTEXITCODE = $realLASTEXITCODE
            return $promptResult
        }
        
        Write-Host "✓ Prompt híbrido (virtualenv + oh-my-posh) configurado" -ForegroundColor Green
    } else {
        # Fallback: prompt simple
        function global:prompt {
            $realLASTEXITCODE = $LASTEXITCODE
            
            Write-Host "PS " -NoNewline -ForegroundColor Blue
            
            if ($env:VIRTUAL_ENV) {
                $envName = Split-Path $env:VIRTUAL_ENV -Leaf
                Write-Host "($envName) " -NoNewline -ForegroundColor Green
            }
            
            Write-Host "$(Get-Location)" -NoNewline
            Write-Host ">" -NoNewline
            
            $global:LASTEXITCODE = $realLASTEXITCODE
            return " "
        }
        
        Write-Host "⚠ Usando prompt simple (oh-my-posh no disponible)" -ForegroundColor Yellow
    }
}

# Función mejorada para workon que mantiene oh-my-posh
function Global:Workon {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, ValueFromPipeline=$true)]
        [string]$Name,
        
        [switch]$List
    )
    
    # Si se pide listar o no se proporciona nombre
    if ($List -or [string]::IsNullOrEmpty($Name)) {
        Write-Host "`nVirtual Environments en: $env:WORKON_HOME" -ForegroundColor Cyan
        Write-Host "=" * 60
        
        if (Test-Path $env:WORKON_HOME) {
            $envs = Get-ChildItem $env:WORKON_HOME -Directory
            if ($envs.Count -gt 0) {
                foreach ($env in $envs) {
                    $hasActivate = Test-Path "$($env.FullName)\Scripts\Activate.ps1"
                    $status = if ($hasActivate) { "✓" } else { "✗" }
                    $color = if ($hasActivate) { "Green" } else { "Red" }
                    Write-Host "  $status $($env.Name)" -ForegroundColor $color
                }
            } else {
                Write-Host "  No hay entornos virtuales" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        return
    }
    
    # Verificar si el entorno existe
    $envPath = Join-Path $env:WORKON_HOME $Name
    if (-not (Test-Path $envPath)) {
        Write-Host "`n✗ El entorno '$Name' no existe" -ForegroundColor Red
        Write-Host "  Usa 'workon -List' para ver los disponibles`n" -ForegroundColor Gray
        return
    }
    
    # Verificar script de activación
    $activateScript = "$envPath\Scripts\Activate.ps1"
    if (-not (Test-Path $activateScript)) {
        Write-Host "`n✗ Script de activación no encontrado" -ForegroundColor Red
        Write-Host "  El entorno parece estar corrupto`n" -ForegroundColor Gray
        return
    }
    
    # Desactivar entorno actual si existe
    if ($env:VIRTUAL_ENV) {
        Write-Host "⇄ Desactivando entorno actual..." -ForegroundColor Gray
        deactivate
    }
    
    # Activar el nuevo entorno
    Write-Host "▶ Activando: $Name" -ForegroundColor Cyan
    
    try {
        # Importar el módulo de activación
        & $activateScript
        
        # Asegurar que oh-my-posh esté configurado
        Set-HybridPrompt
        
        # Verificar que se activó
        if ($env:VIRTUAL_ENV) {
            Write-Host "`n✓ Entorno '$Name' activado" -ForegroundColor Green
            Write-Host "  📁 $(Resolve-Path $envPath)" -ForegroundColor Gray
            
            # Mostrar versión de Python
            $pythonExe = "$envPath\Scripts\python.exe"
            if (Test-Path $pythonExe) {
                $version = & $pythonExe --version 2>&1
                Write-Host "  🐍 $version" -ForegroundColor Gray
            }
            Write-Host ""
        }
    } catch {
        Write-Host "`n✗ Error: $_" -ForegroundColor Red
    }
}

# corrección de la recursión
# Guardar la función original de deactivate
$originalDeactivate = Get-Command deactivate -ErrorAction SilentlyContinue

function Global:deactivate2 {
    # Desactivar cualquier entorno virtual actual
    if ($env:VIRTUAL_ENV) {
        $envName = Split-Path $env:VIRTUAL_ENV -Leaf
        
        # Llamar a la función ORIGINAL de deactivate
        if ($originalDeactivate) {
            & $originalDeactivate
        } else {
            # Fallback: desactivación manual básica
            $env:VIRTUAL_ENV = $null
            $env:VIRTUAL_ENV_PROMPT = $null
            
            # Eliminar la ruta de Scripts del PATH
            $paths = $env:PATH -split ';'
            $cleanPaths = $paths | Where-Object { -not $_.Contains("virtualenv") -or -not $_.Contains("Scripts") }
            $env:PATH = $cleanPaths -join ';'
        }
        
        # Restaurar oh-my-posh
        Set-HybridPrompt
        
        Write-Host "`n✗ Entorno '$envName' desactivado`n" -ForegroundColor Gray
    } else {
        Write-Host "`nℹ No hay entorno virtual activo`n" -ForegroundColor Yellow
    }
}

# Solo establecer alias si no existe uno conflictivo
if (-not (Get-Alias deactivate -ErrorAction SilentlyContinue)) {
    Set-Alias -Name deactivate -Value deactivate2 -Scope Global
}
# Función para salir del entorno y restaurar oh-my-posh completamente
function Reset-PoshPrompt {
    Write-Host "🔄 Restaurando oh-my-posh..." -ForegroundColor Cyan
    Initialize-OhMyPosh -Force
    Write-Host "✓ oh-my-posh restaurado`n" -ForegroundColor Green
}

# ============================================
# CONFIGURACIÓN INICIAL
# ============================================

# 1. Configurar WORKON_HOME si no está definido
if (-not $env:WORKON_HOME) {
    $env:WORKON_HOME = "$HOME\virtualenvs"
}

# 2. Crear directorio si no existe
if (-not (Test-Path $env:WORKON_HOME)) {
    New-Item -ItemType Directory -Path $env:WORKON_HOME -Force | Out-Null
}

# 3. Inicializar oh-my-posh
$ohMyPoshLoaded = Initialize-OhMyPosh

# 4. Configurar prompt híbrido
Set-HybridPrompt

# 5. Mensaje de estado
Write-Host "`n🎨 oh-my-posh (quick-term) + virtualenv integrado" -ForegroundColor Magenta
Write-Host "   Directorio virtualenv: $env:WORKON_HOME" -ForegroundColor Gray
Write-Host "   Comandos: workon, deactivate, Reset-PoshPrompt`n" -ForegroundColor Gray

# 6. Función de diagnóstico
function Get-VenvPoshStatus {
    Write-Host "=== DIAGNÓSTICO INTEGRACIÓN ===" -ForegroundColor Cyan
    
    # oh-my-posh
    $ohMyPosh = Get-Module oh-my-posh -ErrorAction SilentlyContinue
    Write-Host "oh-my-posh: $(if ($ohMyPosh) {'✓ Cargado'} else {'✗ No encontrado'})"
    
    # Theme
    if ($ohMyPosh) {
        Write-Host "Theme: quick-term-omp.json" -ForegroundColor Gray
    }
    
    # Virtualenv
    Write-Host "WORKON_HOME: $env:WORKON_HOME" -ForegroundColor Gray
    Write-Host "Existe: $(if (Test-Path $env:WORKON_HOME) {'✓'} else {'✗'})"
    
    # Entorno actual
    if ($env:VIRTUAL_ENV) {
        Write-Host "`nEntorno ACTUAL: $(Split-Path $env:VIRTUAL_ENV -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "`nEntorno ACTUAL: Ninguno" -ForegroundColor Gray
    }
    
    # Prompt
    Write-Host "`nTipo de prompt: Híbrido (virtualenv + oh-my-posh)" -ForegroundColor Gray
    Write-Host "================================`n" -ForegroundColor Cyan
}