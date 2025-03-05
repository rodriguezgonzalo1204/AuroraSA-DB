/*
Aurora SA
Importación de archivos (Entrega 04)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Francisco Vladimir (46030072) - Vuono Gabriel (42134185)
*/

/*
	Pensado para ejecutarse en un solo bloque, realiza importacion MASIVA de todas las fuentes,
	INDICAR LAS RUTAS CORRESPONDIENTES DE LOS ARCHIVOS, VALOR ACTUAL DEL DOLAR Y CANTIDAD DE CLIENTES RANDOM A GENERAR
*/


IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Com1353G07')
BEGIN
USE Com1353G07														-- Las siguientes rutas son ilustrativas y deben ajustarse --
DECLARE @rutaCatalogoCSV NVARCHAR(250)		= 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\catalogo.csv',
		@rutaElectronicos NVARCHAR(250)		= 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Electronic accessories.xlsx',
		@rutaImportados NVARCHAR(250)		= 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Productos_importados.xlsx',
		@rutaVentas NVARCHAR(250)			= 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Ventas_registradas.csv',
		@rutaComplementario NVARCHAR(250)	= 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx',
		@valorDolar DECIMAL(10,2)			= 1,
		@cantClientes INT					= 100,
		@MensajeError NVARCHAR(MAX);

-- VACIAR TABLAS Y REESTABLECER IDENTITY
/*
EXEC Utilidades.ResetearTablas_sp
GO
*/

<<<<<<< HEAD
SET NOCOUNT ON;
=======
>>>>>>> 5bfc5656fc9d33777b39dc000d08f888af1918b2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRY
    BEGIN TRANSACTION;
    EXEC Inventario.CargarProductosCatalogoCSV_sp @rutaCatalogoCSV, @rutaComplementario, @valorDolar;
    COMMIT TRANSACTION;
    PRINT 'Importación de catálogo CSV completada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SET @MensajeError = 'Error en CargarProductosCatalogoCSV_sp: ' + ERROR_MESSAGE();
    RAISERROR(@MensajeError, 16, 1);
END CATCH;


BEGIN TRY
    BEGIN TRANSACTION;
	EXEC Inventario.CargarProductosElectronicos_sp @rutaElectronicos, @valorDolar
    COMMIT TRANSACTION;
    PRINT 'Importación de productos electrónicos completada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SET @MensajeError = 'Error en CargarProductosElectronicos_sp: ' + ERROR_MESSAGE();
    RAISERROR(@MensajeError, 16, 1);
END CATCH;


BEGIN TRY
    BEGIN TRANSACTION;
	EXEC Inventario.CargarProductosImportados_sp @rutaImportados, @valorDolar
    COMMIT TRANSACTION;
    PRINT 'Importación de productos importados completada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SET @MensajeError = 'Error en CargarProductosImportados_sp: ' + ERROR_MESSAGE();
    RAISERROR(@MensajeError, 16, 1);
END CATCH;


BEGIN TRY
    BEGIN TRANSACTION;
	EXEC Empresa.ImportarSucursales_sp @rutaComplementario
    COMMIT TRANSACTION;
    PRINT 'Importación de sucursales completada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SET @MensajeError = 'Error en ImportarSucursales_sp: ' + ERROR_MESSAGE();
    RAISERROR(@MensajeError, 16, 1);
END CATCH;


BEGIN TRY
    BEGIN TRANSACTION;
	EXEC Empresa.ImportarEmpleados_sp @rutaComplementario
    COMMIT TRANSACTION;
    PRINT 'Importación de empleados completada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SET @MensajeError = 'Error en ImportarEmpleados_sp: ' + ERROR_MESSAGE();
    RAISERROR(@MensajeError, 16, 1);
END CATCH;


BEGIN TRY
    BEGIN TRANSACTION;
	EXEC Ventas.CargarClientesAleatorios_sp @cantClientes
    COMMIT TRANSACTION;
<<<<<<< HEAD
    PRINT CAST(@cantClientes AS VARCHAR) + ' clientes aleatorios cargados correctamente.';
=======
    PRINT 'Generación aleatoria de clientes completada.';
>>>>>>> 5bfc5656fc9d33777b39dc000d08f888af1918b2
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SET @MensajeError = 'Error en CargarClientesAleatorios_sp: ' + ERROR_MESSAGE();
    RAISERROR(@MensajeError, 16, 1);
END CATCH;


BEGIN TRY
    BEGIN TRANSACTION;
	EXEC Ventas.ImportarVentas_sp @rutaVentas, @valorDolar
    COMMIT TRANSACTION;
    PRINT 'Importación de ventas completada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SET @MensajeError = 'Error en ImportarVentas_sp: ' + ERROR_MESSAGE();
    RAISERROR(@MensajeError, 16, 1);
END CATCH;

END
ELSE
	PRINT 'Debe crear la base de datos previamente'

