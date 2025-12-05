@{
    # METADATOS BÁSICOS
    ModuleVersion = '12.7.8' # Usamos la versión de PyPI del proyecto original.
    Author = 'Guillermo López / regisf'
	Forked by = RS Montalvo / Touxstone 
	GUID [for this fork] = 8b9ad21e-2178-4192-b4bf-d1b8958581b6
    CompanyName = 'io'
    Copyright = '(c) 2012-2025 regisf. Todos los derechos reservados.'
    8b9ad21e-2178-4192-b4bf-d1b8958581b6
    # ARCHIVOS
    # Aquí se apunta al archivo del módulo principal.
    ModuleToProcess = 'VirtualEnvWrapper.psm1'
    
    # RESTRICCIONES DE CARGA (¡Lo más importante!)
    # Esto asegura que SÓLO se exporten los comandos que el usuario necesita.
    FunctionsToExport = @(
        'Get-VirtualEnvs', # lsvirtualenv
        'New-VirtualEnv',  # mkvirtualenv
        'Remove-VirtualEnv', # rmvirtualenv
        'Workon',          # workon
        'Get-VirtualEnvsVersion' 
    )
    
    # También podemos exportar los alias para conveniencia.
    AliasesToExport = @(
        'lsvirtualenv',
		'workon',
        'mkvirtualenv',
        'rmvirtualenv',
		'mktmpenv',
		'deactivate'
    )
    
    # Configuramos el tipo de shell de destino (PowerShell 5.1/Core)
    CompatiblePSEditions = @('Core', 'Desktop')

    # Especificamos el entorno de Python si fuera necesario, aunque el .psm1 ya lo maneja.
    # RootModule = 'VirtualEnvWrapper.psm1'
    
    # Otros detalles
    Description = 'PowerShell wrapper for Python virtualenv, a clone of virtualenvwrapper.'
    
    # Si dependiera de otros módulos, se listarían aquí:
    # RequiredModules = @()
}