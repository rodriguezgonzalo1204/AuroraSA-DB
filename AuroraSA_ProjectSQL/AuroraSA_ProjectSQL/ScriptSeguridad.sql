/*
Aurora SA
Requisitos de seguridad. (Entrega 05)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/


USE Com1353G07
GO

--- Creamos logins para iniciar sesión
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Aurora')
	CREATE LOGIN Aurora WITH PASSWORD = 'AplicadasVerano';
ELSE
    PRINT 'El login ya existe.';
GO	

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'Cenicienta')
    CREATE LOGIN Cenicienta WITH PASSWORD = 'AguanteBDD';
ELSE
    PRINT 'El login ya existe.';
GO

--- Creamos usuarios para la base de datos
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'VladimirFrancisco')
  CREATE USER VladimirFrancisco FOR LOGIN Aurora;
ELSE
    PRINT 'El usuario ya existe.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'GonzaloRodriguez')
  CREATE USER GonzaloRodriguez FOR LOGIN Cenicienta;
ELSE
    PRINT 'El usuario ya existe.';
GO

--- Creamos roles de servidor
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Supervisor')
    CREATE ROLE Supervisor;
ELSE
    PRINT 'El rol ya existe.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Cajero')
    CREATE ROLE Cajero;
ELSE
    PRINT 'El rol ya existe.';
GO

-- Ejecutar hasta acá
--------------------------------------------


--- Ahora otorgamos roles a nuestros usuarios
ALTER ROLE Supervisor ADD MEMBER VladimirFrancisco;
GO
ALTER ROLE Cajero ADD MEMBER GonzaloRodriguez;
GO
-- Ejecutar hasta acá


-- Se crea un procedimiento para generar notas de credito
CREATE OR ALTER PROCEDURE Seguridad.GenerarNotaCredito
    @facturaID		INT,
    @clienteID		INT,
    @monto		DECIMAL(18, 2),
    @detalles		VARCHAR(60) 
AS
	BEGIN
    -- Verificar que la factura esté pagada
    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @FacturaID AND activo = 1)
    BEGIN
        RAISERROR('La factura no está activa. No se puede generar la nota de crédito.', 16, 1);
        RETURN;
    END;

    -- Realizar nota de crédito
    INSERT INTO Ventas.NotaCredito (facturaId, idCliente, monto, fechaEmision, detalles)
    VALUES (@facturaID, @clienteID, @monto, GETDATE(), @detalles);

    PRINT 'Nota de crédito generada exitosamente.';
END;


--- Permitimos acceso a los Supervisores para la ejecución del procedure
GRANT EXECUTE ON Seguridad.GenerarNotaCredito TO Supervisor;
GO

--- Denegamos permisos para ejecutar el procedure a otros roles
DENY EXECUTE ON Seguridad.GenerarNotaCredito TO Cajero;
GO


-- Ejecutamos como el usuario 'GonzaloRodriguez'
EXECUTE AS USER = 'GonzaloRodriguez';
EXEC Seguridad.GenerarNotaCredito 2,60,6.25,'Palangana' ;
REVERT;
-- Resultado esperado -> No tiene permisos

-- Ejecutamos como 'VladimirFrancisco' (Supervisor)
EXECUTE AS USER = 'VladimirFrancisco';
EXEC Seguridad.GenerarNotaCredito 2,60,6.25,'Palangana' ;
REVERT;

SELECT * FROM Ventas.NotaCredito
-- Resultado esperado -> Nota de Crédito insertada


------------------------------------------------------------------

-- ENCRIPTACION

-- Agregar columnas encriptadas
ALTER TABLE Empresa.Empleado
ADD CUIL_encriptado VARBINARY(256),
    domicilio_encriptado VARBINARY(256),
    telefono_encriptado VARBINARY(256),
    mailPersonal_encriptado VARBINARY(256);

-- Creamos procedure para encriptar los campos de los empleados
CREATE OR ALTER PROCEDURE Seguridad.EncriptarEmpleado
	@fraseClave NVARCHAR(128)
AS 
BEGIN 
--- Encripración masiva para toda la tabla (de forma que siempre que se ingresen datos nuevos 
--- basta con hacer un EXECUTE para encriptar)
	UPDATE Empresa.Empleado
		SET CUIL_encriptado = EncryptByPassPhrase(@fraseClave, CUIL, 1, CONVERT(VARBINARY, idEmpleado)),
			telefono_encriptado = EncryptByPassPhrase(@fraseClave, telefono, 1, CONVERT(VARBINARY, idEmpleado)),
			mailPersonal_encriptado = EncryptByPassPhrase(@fraseClave, mailPersonal, 1, CONVERT(VARBINARY, idEmpleado)),
			domicilio_encriptado = EncryptByPassPhrase(@fraseClave, domicilio, 1, CONVERT(VARBINARY, idEmpleado))
END

-- Ejecutar hasta acá <--


EXEC Seguridad.EncriptarEmpleado 'NoTeOlvidesElWhereEnElDeleteFrom'
SELECT * from Empresa.Empleado
-- Visualizamos los datos encriptados en los nuevos campos

/*
-- Con estas sentencias podemos eliminar los campos originales, quedandonos solo con los encriptados
ALTER TABLE Empresa.Empleado
DROP COLUMN CUIL,
DROP COLUMN domicilio,
DROP COLUMN telefono,
DROP COLUMN mailPersonal;

-- Misma forma pero renombrando las columnas
EXEC sp_rename 'Empresa.Empleado.CUIL_encriptado', 'CUIL', 'COLUMN';
EXEC sp_rename 'Empresa.Empleado.domicilio_encriptado', 'domicilio', 'COLUMN';
EXEC sp_rename 'Empresa.Empleado.telefono_encriptado', 'telefono', 'COLUMN';
EXEC sp_rename 'Empresa.Empleado.mailPersonal_encriptado', 'mailPersonal', 'COLUMN';
*/

-- Desencriptar los datos
DECLARE @fraseClave NVARCHAR(128) = 'NoTeOlvidesElWhereEnElDeleteFrom';
SELECT 
    idEmpleado,
    CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, CUIL_encriptado, 1, CONVERT(VARBINARY, idEmpleado))) AS CUIL,
    CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, domicilio_encriptado, 1, CONVERT(VARBINARY, idEmpleado))) AS domicilio,
    CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, telefono_encriptado, 1, CONVERT(VARBINARY, idEmpleado))) AS telefono,
    CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, mailPersonal_encriptado, 1, CONVERT(VARBINARY, idEmpleado))) AS mailPersonal
FROM Empresa.Empleado;

