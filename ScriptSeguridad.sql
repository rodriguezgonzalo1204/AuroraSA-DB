/*
Entrega 05
Seguridad
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

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Operario')
    CREATE ROLE Operario;
ELSE
    PRINT 'El rol ya existe.';
GO

--- Ahora otorgamos roles a nuestros usuarios

ALTER ROLE Supervisor ADD MEMBER VladimirFrancisco;
GO

ALTER ROLE Operario ADD MEMBER GonzaloRodriguez;
GO

--- Tabla nueva

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Ventas' AND TABLE_NAME ='NotaCredito')
BEGIN
CREATE TABLE Ventas.NotaCredito
(
	idNota INT IDENTITY (1,1) PRIMARY KEY,
	facturaId INT FOREIGN KEY REFERENCES Ventas.Factura(idFactura),
	idCliente INT FOREIGN KEY REFERENCES Ventas.Cliente(idCliente),
	monto DECIMAL(10,2),
	fechaEmision DATE,
	detalles VARCHAR(60)
 )
 END
 GO

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
    INSERT INTO Ventas.NotaCredito (facturaId, idCliente, monto, fechaEmision)
    VALUES (@facturaID, @clienteID, @monto, GETDATE());

    PRINT 'Nota de crédito generada exitosamente.';
END;

--- Permitimos acceso a los Supervisores para la ejecución del procedure

GRANT EXECUTE ON Ventas.GenerarNotaCredito TO Supervisor;
GO

--- Denegamos permisos para ejecutar el procedure a otros roles

DENY EXECUTE ON Ventas.GenerarNotaCredito TO Operario;
GO

--- La siguiente consulta permite visualizar como se encuentran los permisos
--- respecto a usuarios para un procedure
SELECT 
    pr.principal_id,
    pr.name AS Usuario_o_Rol,
    pr.type_desc AS Tipo,
    pe.permission_name AS Permiso,
    pe.state_desc AS Estado
FROM 
    sys.database_permissions pe
INNER JOIN 
    sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE 
    pe.major_id = OBJECT_ID('Ventas.GenerarNotaCredito')
    AND pe.permission_name = 'EXECUTE';
