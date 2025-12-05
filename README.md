# VirtualEnvWrapper for Windows Powershell

This is a mimic of the powerfull [virtualenvwrapper](https://bitbucket.org/virtualenvwrapper/) but for [Windows Powershell](https://bitbucket.org/virtualenvwrapper/). 

Unless the previous version of my esteemed colleague [Guillermo Lòpez](https://bitbucket.org/guillermooo/virtualenvwrapper-powershell/overview) equivalent but obsolete it's compatible with Python 2+ and entierly based on a PowerShell script.

## Installation

Just use the `Install.ps1` script:

```powershell
./Install.ps1
```

and the script will create required path if needed and install the `profile.ps1` file directly to 
automaticly activate VirtualEnvWrapper when the shell is opened

### Manual Installation 
Put the file `VirtualEnvWrapper.psm1` into the directory `~\Documents\WindowsPowerShell\Modules`.
Edit or create the file `~\Documents\WindowsPowerShell\Profile.ps1` (see )
and add into the lines below :

```powershell
$MyDocuments = [Environment]::GetFolderPath("mydocuments")
Import-Module $MyDocuments\WindowsPowerShell\Modules\VirtualEnvWrapper.psm1
```

## Location

The virtual environments directory is set into your personnal directory : `~/Envs` 

Where `~` is your personnal directory.

If you want to set your environment. Just add and variable environment called :

`WORKON_HOME` (as in Unix/Linux system).


## Usage

The module add few commands in Powershell : 

* `lsvirtualenv` (alias: Get-VirtualEnvs) : List all Virtual environments
* `mkvirtualenv` (alias: New-VirtualEnv) : Ceate a new virtual environment
* `rmvirtualenv` (alias: Remove-VirtualEnv) : Remove an existing virtual environment
* `workon`: Activate an existing virtual environment
* `Get-VirtualEnvsVersion`: to display the current version.

### Create a virtual environment

To create a virtual environment just type:

    MkVirtualEnv -Name MyEnv -Python ThePythonDistDir

where `MyEnv` is your environment and `ThePythonDistDir` is where the `python.exe` live.  For example:

    MkVirtualEnv -Name MyProject -Python c:\Python36 

will create and virtual environment named `MyProject` located at `~\Envs` with the Python 3.6 distribution located at `C:\Python36` 

If the `-Python` option is not set, the python command set in your path is used by default.

Options are:

* `-Name` : The new environment name
* `-Packages` or `-i` : Install packages separated by a coma (Note: this differs from [original virtualenvwrapper](https://bitbucket.org/virtualenvwrapper/virtualenvwrapper/src/master/) )
* `-Associate` or `-a`: Still todo
* `-Requirement` or `-r`: The requirement file to load. 

If both options Packages and Requirement are set, the script will install first the packages then the requirements as in original Bash script.


### List virtual environments

Type

    LsVirtualEnv

in a Powershelll to display the entiere list with the Python version.

For Example:

```
Python Virtual Environments available

Name                          Python version
====                          ==============
TheProjectIHave               3.6.3
```

### Activate a virtual environment

Type

    workon TheEnvironment

in a console. The PS command line starts now with:

    (TheEnvironment) C:\Somewhere>

to show you what is the default 

To ensure that the Python environment is the good one type:

    Get-Command python

The path should be:

    ~\Envs\TheEnvironment\Scripts\python.exe


### Leave from a virtual environment

Just type `deactivate` as usual (Python default).

## Todo

* Activate the autocompletion
* Set the virtualenvwrapper options into system environment variables (see the main project)

### Development

A script `InstallDev.ps1` exists to simplify the development. Invoke it with:

    $ .\InstallDev.ps1 

will unload `VirtualEnvWrapper.ps1` from memory and reload it.

# [Fork Adds](#fork-adds-concise-english-version)
# 🚀 Instalación Mejorada y Solución de Problemas (PowerShell Core / PS 7+)

Esta documentación complementa las instrucciones originales de `virtualenvwrapper-powershell`, proporcionando un método de instalación manual robusto y soluciones para los *bugs* específicos encontrados en **PowerShell Core (PS 7+)** que impiden la carga correcta y el funcionamiento de `workon`.

Además, se incluye la configuración de **Oh My Posh** para integrar el indicador del entorno virtual de Python (`(venv)`) directamente en el *prompt* personalizado.

## 1\. 📂 Instalación Manual y Organización del Módulo

La instalación manual garantiza que el módulo se cargue en la ruta moderna de PowerShell Core y que puedas aplicar las correcciones necesarias al código.

### A. Preparación de Archivos

1.  **Rutas Clave:** Confirma que tu directorio de módulos sea la ruta moderna (sin "Windows"):

      * `C:\Users\TuUsuario\Documents\PowerShell\Modules`

2.  **Creación de la Carpeta:** Crea la carpeta del módulo:

    ```powershell
    mkdir C:\Users\TuUsuario\Documents\PowerShell\Modules\VirtualEnvWrapper
    ```

3.  **Archivos del Módulo:** Descarga `VirtualEnvWrapper.psm1` del repositorio y colócalo en la nueva carpeta. (Opcional, pero recomendado) Crea un archivo **`VirtualEnvWrapper.psd1`** (Manifiesto del Módulo) para adherirte a las buenas prácticas de PowerShell.

4.  **Desbloqueo de Archivos:** Dado que el archivo `.psm1` fue descargado de Internet, debe ser desbloqueado para que `RemoteSigned` lo ejecute:

    ```powershell
    Unblock-File -Path C:\Users\TuUsuario\Documents\PowerShell\Modules\VirtualEnvWrapper\VirtualEnvWrapper.psm1
    ```

### B. Correcciones Críticas de Código (Bug de PS 7+)

Se deben realizar las siguientes correcciones directamente en el archivo `VirtualEnvWrapper.psm1` para evitar fallos de ámbito (*scope*) y la creación incorrecta del directorio `~\Envs`.

1.  **Corregir la Activación (`workon`):** El comando nativo de activación debe usar *dot-sourcing* para modificar el *prompt* de PowerShell.

      * **Ubicación:** Función `Workon` (alrededor de la línea 318).
      * **Cambiar:**
        ```powershell
        Import-Module $activate_path -Force
        ```
      * **A:**
        ```powershell
        . $activate_path # Usa dot-sourcing para ejecutar en el ámbito actual
        ```

2.  **Corregir el Fallo de Inicialización (Bug de Asignación):** La lógica de asignación inicial falla al leer la variable de entorno, causando que el módulo siempre use el valor por defecto (`~\Envs`).

      * **Solución Quirúrgica:** Reemplazar el bloque de inicialización para forzar la lectura correcta y eliminar la lógica de contingencia fallida. (Ver el último código propuesto).

-----

## 2\. 📝 Configuración en el `$PROFILE`

El orden de las líneas en tu script de perfil (`$PROFILE`) es **CRÍTICO**. La variable `$env:WORKON_HOME` debe definirse *antes* de que el módulo sea importado.

Abre `C:\Users\TuUsuario\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` y usa la siguiente estructura:

```powershell
# --- Configuración de virtualenvwrapper-powershell ---

# 1. DEFINIR la ruta de los entornos virtuales (¡CRÍTICO: PRIMERO!)
$env:WORKON_HOME = "$HOME\.virtualenvs"

# 2. (Opcional) Asegurar la existencia y ocultar la carpeta en Windows
if (-not (Test-Path -Path $env:WORKON_HOME -PathType Container)) {
    New-Item -Path $env:WORKON_HOME -ItemType Directory -Force | Out-Null
    (Get-Item $env:WORKON_HOME).Attributes += 'Hidden'
}

# 3. IMPORTAR el módulo (¡SEGUNDO!)
Import-Module VirtualEnvWrapper

# --- Configuración de Oh My Posh ---

# Si usas Oh My Posh, carga el motor y tu tema aquí:
oh-my-posh init pwsh --config 'C:\Users\TuUsuario\MiTema.omp.json' | Invoke-Expression
```

-----

## 3\. ✨ Integración con Oh My Posh

Para que el *prompt* de Oh My Posh muestre el nombre del entorno virtual (ejemplo: `(venv) C:\ruta>`), necesitas que tu tema (`.omp.json`) tenga un segmento configurado para Python.

### A. Verificar la Integración

Asegúrate de que tu archivo de configuración de Oh My Posh (ej: `MiTema.omp.json`) contenga un segmento con el siguiente tipo:

```json
{
    "type": "python",
    "style": "powerline",
    "template": " \uE235 {{ .Venv }} "
    // ... otros ajustes ...
}
```
### En este ejemplo
El `$PROFILE` después de la la línea `Set-PSReadLineOption -EditMode Emacs` que define el modo edición y atajos de teclado tipo `EMACS` la definicón de tema `oh-my-posh` se lee:
```PS
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\quick-term.omp.json" | Invoke-Expression
```

### B. Solución al Conflicto de Aliases

En PowerShell Core, el *bug* de alias *case-insensitive* puede afectar funciones clave como `workon`, por ello estos ajustes se han montado en una capa posterior como es el $PROFILE. En una versión siguiente y quizá independiente de este ajuste, o `TO-DO` el ajuste sería evitar la creación del `alias` `workon` (o crearlo aociado a nombre matriz diferente e.g. `invoke-Workon`) pero en vista que PS es `case insensitive` tampoco haría falta. 

Al seguir estos pasos, se resuelve la inestabilidad de `virtualenvwrapper-powershell` en PS 7+ y se integra perfectamente con la experiencia visual de Oh My Posh.

-----

## Fork Adds (Concise English Version)

-----

# 🚀 Enhanced Installation and Patching for PowerShell Core (PS 7+)

This guide supplements the original `virtualenvwrapper-powershell` instructions by detailing the manual installation and the **essential `$PROFILE` adjustments** required to fix known scope bugs and alias conflicts in **PowerShell Core (PS 7+)**.

The steps also include integrating the custom prompt engine **Oh My Posh** to display the Python virtual environment indicator (`(venv)`).

## 1\. 📂 Manual Module Installation

Ensure the module is correctly placed and unblocked in your system:

  * **Path:** The base directory should be `C:\Users\YourUser\Documents\PowerShell\Modules`.
  * **Files:** Download `VirtualEnvWrapper.psm1` (and optionally create `VirtualEnvWrapper.psd1`) into the `VirtualEnvWrapper` folder.

### 🚨 Unblock Files

To allow PowerShell to execute the downloaded code, remove the "Mark of the Web":

```powershell
Unblock-File -Path C:\Users\YourUser\Documents\PowerShell\Modules\VirtualEnvWrapper\VirtualEnvWrapper.psm1
```

-----

## 2\. 📝 `$PROFILE` Configuration (Critical Order)

The order of execution in your `$PROFILE` script is **CRITICAL** to ensure the module uses your preferred path and doesn't default to creating `~\Envs`.

Open your `$PROFILE` (`C:\Users\...\Microsoft.PowerShell_profile.ps1`) and use this structure:

```powershell
# --- virtualenvwrapper-powershell Configuration ---

# 1. DEFINE the virtual environment path (CRITICAL: FIRST!)
$env:WORKON_HOME = "$HOME\.virtualenvs"

# 2. (Optional) Ensure the folder exists and is hidden
if (-not (Test-Path -Path $env:WORKON_HOME -PathType Container)) {
    New-Item -Path $env:WORKON_HOME -ItemType Directory -Force | Out-Null
    (Get-Item $env:WORKON_HOME).Attributes += 'Hidden'
}

# 3. IMPORT the module (SECOND!)
Import-Module VirtualEnvWrapper

# --- Alias Conflict Patch ---
# This alias ensures that the function is correctly invoked despite the case-insensitive bug:
Set-Alias -Name workon -Value Workon -Force

# --- Oh My Posh Configuration ---

# Load the custom prompt engine and your theme:
oh-my-posh init pwsh --config 'C:\Users\YourUser\MyTheme.omp.json' | Invoke-Expression
```

-----

## 3\. ✨ Oh My Posh Integration

For your custom prompt to display the virtual environment name (e.g., `(venv)`), your theme file (`.omp.json`) must include a `python` segment:

```json
{
    "type": "python",
    "style": "powerline",
    "template": " \uE235 {{ .Venv }} "
    // ...
}
```