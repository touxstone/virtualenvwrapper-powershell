# Guía Definitiva: (Virtual_Environment) Entorno Python 2026 en PowerShell 7.5.4+ (Sin dramas)
## by RS Montalvo

Si intentas configurar Python en Windows hoy en día, te vas a encontrar con tres dragones: los **alias fantasmas** de la Microsoft Store, un **Oh My Posh** que se "come" los prompts de Python, y **módulos de gestión (wrappers)** de hace 5 años que congelan la terminal.

Después de muchas pruebas, aquí está el método "quirúrgico" para tener un entorno profesional, ligero y ultra-veloz.

## 1. Limpieza de "Fantasmas"

Antes de instalar nada, hay que matar al culpable de que el comando `python` te lleve a la Store.

* Ve a **Configuración > Alias de ejecución de aplicaciones**.
* **Desactiva** todos los que digan "Python" o "Instalador de Python".

## 2. El Motor: Python 3.14 (Standalone)

No uses la versión de la Store. Ve a [python.org](https://www.python.org) y baja el **Windows Installer (64-bit)**.

* **CRUCIAL:** Marca la casilla **"Add Python to PATH"**.
* Al final, elige **"Disable path length limit"**.

---

## 3. El Perfil Maestro de PowerShell (`$PROFILE`)

Olvida los módulos de 600 líneas que fallan. Abre tu perfil (`notepad $PROFILE`) y pega este motor optimizado para **PWSH 7.5.4**.

### A. Configuración de Edición (Modo Emacs + Tab Inteligente)

Muchos colegas sufren porque el Tab se vuelve loco en modo Emacs. Aquí la solución:

```powershell
Set-PSReadLineOption -EditMode Emacs
# Tab con menú visual y sugerencias de historial
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

```

### B. El "Virtualenv-Wrapper" de nueva generación (Solo 40 líneas)

Este bloque gestiona tus entornos en una carpeta oculta en tu Home (`$HOME\.virtualenvs`).

```powershell
$env:WORKON_HOME = "$HOME\.virtualenvs"
if (!(Test-Path $env:WORKON_HOME)) { New-Item $env:WORKON_HOME -ItemType Directory -Force | Out-Null }

# Crear y entrar automáticamente
function mkvirtualenv ($name) {
    $target = "$env:WORKON_HOME\$name"
    if (Test-Path $target) { 
        Write-Host "⚠️ Ya existe. ¿Activar? (s/n)"; if ((Read-Host) -eq 's') { workon $name }
        return 
    }
    Write-Host "🛠️ Creando entorno $name..." -ForegroundColor Cyan
    python -m venv $target
    if (Test-Path "$target\Scripts\Activate.ps1") { . "$target\Scripts\Activate.ps1"; Write-Host "✅ Activo." -ForegroundColor Green }
}

# Activar con 'workon'
function workon ($name) {
    $path = "$env:WORKON_HOME\$name\Scripts\Activate.ps1"
    if (Test-Path $path) { . $path } else { Write-Error "No existe el entorno." }
}

# Salida segura (Cambiado a 'off' para evitar colisiones con OMP/Python)
function off {
    $native = Get-Command deactivate -ErrorAction SilentlyContinue -CommandType Function
    if ($native) { & $native; Write-Host "🔌 Desconectado." -ForegroundColor Yellow }
    elseif ($env:VIRTUAL_ENV) { Remove-Item Env:\VIRTUAL_ENV; Write-Host "🧹 Limpio." -ForegroundColor Cyan }
}

function lsvirtualenv { Get-ChildItem $env:WORKON_HOME | Select-Object Name }

```

---

## 4. El Problema de Oh My Posh (OMP)

Si usas OMP, verás que al hacer `workon`, el nombre del entorno **no aparece**. Esto es porque OMP redibuja el prompt y oculta el cambio de Python.

**La solución:** No pelees con el script de Python. Asegúrate de que tu tema de OMP (`.omp.json`) incluya un segmento de tipo `python`. Si no, usa el comando `off` que creamos arriba; aunque no lo veas, el mensaje "Desconectado" te confirmará que has salido.

## Por qué este setup es mejor:

1. **Sin Colisiones:** Usamos `off` en lugar de `deactivate` para evitar que la terminal se congele por recursión infinita (un bug común en PWSH 7.5).
2. **Conciso:** Menos código = menos errores.
3. **Poderoso:** Tienes autocompletado tipo IDE en la terminal gracias a las `PSReadLineOption`.

## 🛠️ Troubleshooting: Preparando el Terreno

Si eres de los "guerreros" que están instalando esto en un sistema limpio, te vas a encontrar con que Windows bloquea scripts por defecto. Aquí los pasos de rescate:

### 1. Crear y editar tu $PROFILE desde cero

No busques la carpeta a mano, deja que PowerShell la cree por ti:

```powershell
if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -Type File -Force }
notepad $PROFILE

```

### 2. Habilitar la ejecución de Scripts

Si al reiniciar PWSH ves un error rojo diciendo que "la ejecución de scripts está deshabilitada", ejecuta esto como **Administrador**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

```

> **¿Quieres saber más?** Consulta la documentación oficial de Microsoft sobre [Execution Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

---

## 🎨 Visualización Dinámica de Temas (Oh My Posh)

¿No te decides por un tema? Añade este "Probador de Temas" a tu `$PROFILE`. Te permite saltar entre todos los temas descargados con un simple comando:

```powershell
# --- Utilidades de Temas ---
$POSH_THEMES_PATH = "$HOME\.poshThemes"
$available = Get-ChildItem $POSH_THEMES_PATH | ForEach-Object {$_.BaseName}
$available_list = $($available -join ', ')

function Set-PoshTheme {
    param([string]$ThemeName)
    $themePath = "$POSH_THEMES_PATH\$ThemeName.omp.json"
    if (Test-Path $themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
        Write-Host "🎨 Theme cambiado a: $ThemeName" -ForegroundColor Green
    } else {
        Write-Warning "$ThemeName no existe. Disponibles: $available_list"
    }
}

Set-Alias posh Set-PoshTheme

```

**Uso:** Escribe `posh <nombre_del_tema>` para cambiarlo al vuelo.

---

## 🐍 Cómo hacer que OMP "vea" tu Python

Para que el nombre de tu entorno virtual aparezca en tu barra de herramientas (prompt) de forma elegante, debes editar tu archivo `.omp.json` favorito y pegar este segmento dentro de la lista de `segments`:

```json
{
  "type": "python",
  "style": "powerline",
  "foreground": "#111111",
  "background": "#FFDE57",
  "powerline_symbol": "\u00e0\u00b0",
  "template": " \u00e2\u0093\u00b5 {{ if .Venv }}({{ .Venv }}) {{ end }}{{ .Full }} ",
  "properties": {
    "display_mode": "environment",
    "fetch_virtual_env": true,
    "home_enabled": true
  }
}

```

### ¿Qué hace este segmento?

* **Icono Dinámico:** Muestra el logo de Python (`\ue235`).
* **Detección Automática:** Solo se enciende cuando haces `workon`. Si haces `off`, el segmento desaparece mágicamente, manteniendo tu terminal limpia.
* **Información:** Te muestra tanto el nombre del venv como la versión de Python activa.

---

## 🔤 El Toque Final: No más cuadraditos (Nerd Fonts)

Si después de configurar todo ves caracteres extraños en tu terminal, es porque tu fuente actual no sabe "dibujar" los iconos de Python o de carpetas. Necesitas una **Nerd Font**.

### 1. La forma fácil (Desde la Terminal)

Ya no necesitas navegar por webs confusas. Oh My Posh tiene un instalador de fuentes integrado. Ejecuta esto:

```powershell
oh-my-posh font install

```

* Selecciona una fuente popular (recomiendo **MesloLGL Nerd Font** o **JetBrainsMono**).
* El comando la descargará e instalará en tu sistema automáticamente.

### 2. Configurar la Terminal (El paso que todos olvidan)

Instalar la fuente no es suficiente; tienes que decirle a tu terminal que la use:

1. Abre tu **Windows Terminal**.
2. Ve a **Configuración** (o pulsa `Ctrl + ,`).
3. En el menú de la izquierda, busca **Perfiles > PowerShell**.
4. Ve a la pestaña **Apariencia**.
5. En "Tipo de fuente", selecciona la que acabas de instalar (ej. `MesloLGL NF`).
6. **Guarda** y verás cómo los iconos cobran vida.

---

## 🚀 Conclusión: Tu nuevo flujo de trabajo

Ahora sí, cuando abras tu terminal, el cielo es el límite:

1. **Edición fluida:** Modo Emacs con un Tab que no falla.
2. **Estética:** Un tema de OMP que cambia con el comando `posh`.
3. **Productividad:** Creas entornos con `mkvirtualenv`, entras con `workon` y sales con `off`.
4. **Claridad:** El segmento de Python te grita en qué entorno estás para que no instales librerías donde no debes.

¡Disfruta de la terminal más potente y concisa de 2026!
>>>>> línea fechada 24/2 7:03 PM y probar la conexión que ahora hay entre el acceso Win11 y WSL/ubuntu
