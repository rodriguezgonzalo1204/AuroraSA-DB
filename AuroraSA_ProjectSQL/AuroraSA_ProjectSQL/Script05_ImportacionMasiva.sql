/*
Aurora SA
Importación de archivos (Entrega 04)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/

/*
	Pensado para ejecutarse en un solo bloque, realiza importacion MASIVA de todas las fuentes,
	INDICAR LAS RUTAS CORRESPONDIENTES DE LOS ARCHIVOS, VALOR ACTUAL DEL DOLAR Y CANTIDAD DE CLIENTES RANDOM A GENERAR
*/

Use Com1353G07
GO

DECLARE @rutaCatalogoCSV NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\catalogo.csv',
		@rutaElectronicos NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Electronic accessories.xlsx',
		@rutaImportados NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Productos_importados.xlsx',
		@rutaVentas NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Ventas_registradas.csv',
		@rutaComplementario NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx',
		@valorDolar DECIMAL(10,2) = 1,
		@cantClientes INT = 100;

-- VACIAR TABLAS Y REESTABLECER IDENTITY
/*
SET NOCOUNT ON;
EXEC Utilidades.ResetearTablas_sp
GO
*/

EXEC Inventario.CargarProductosCatalogoCSV_sp @rutaCatalogoCSV, @rutaComplementario, @valorDolar
EXEC Inventario.CargarProductosElectronicos_sp @rutaElectronicos, @valorDolar
EXEC Inventario.CargarProductosImportados_sp @rutaImportados, @valorDolar
EXEC Empresa.ImportarSucursales_sp @rutaComplementario
EXEC Empresa.ImportarEmpleados_sp @rutaComplementario
EXEC Ventas.CargarClientesAleatorios_sp @cantClientes
EXEC Ventas.ImportarVentas_sp @rutaVentas, @valorDolar





