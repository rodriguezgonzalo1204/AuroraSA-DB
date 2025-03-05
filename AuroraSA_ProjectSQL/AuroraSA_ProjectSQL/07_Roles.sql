/*
Aurora SA
Creacion de roles y procedure de notas de crédito. (Entrega 05)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Francisco Vladimir (46030072) - Vuono Gabriel (42134185)
*/

/*
	 El script debe ejecutarse siguiendo las indicaciones
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
-- 1) Ejecutar hasta aca


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
-- 2) Ejecutar hasta aca


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
-- 3) Ejecutar hasta aca


--- Ahora otorgamos roles a nuestros usuarios
ALTER ROLE Supervisor ADD MEMBER VladimirFrancisco;
GO
ALTER ROLE Cajero ADD MEMBER GonzaloRodriguez;
GO
-- 4) Ejecutar hasta aca


-- Se crea un procedimiento para generar notas de credito
CREATE OR ALTER PROCEDURE Seguridad.GenerarNotaCredito_sp
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
    INSERT INTO Ventas.NotaCredito (idFactura, idCliente, monto, fechaEmision, detalles)
    VALUES (@facturaID, @clienteID, @monto, GETDATE(), @detalles);

    PRINT 'Nota de crédito generada exitosamente.';
END;
-- 5) Ejecutar hasta aca


--- Permitimos acceso a los Supervisores para la ejecución del procedure
GRANT EXECUTE ON Seguridad.GenerarNotaCredito_sp TO Supervisor;
GO
-- 6) Ejecutar hasta aca


--- Denegamos permisos para ejecutar el procedure a otros roles
DENY EXECUTE ON Seguridad.GenerarNotaCredito_sp TO Cajero;
GO
-- 7) Ejecutar hasta aca



-- Ejecutamos como el usuario 'GonzaloRodriguez', que posee rol "Cajero",
-- por lo que no debe tener permisos para realizar notas de crédito
EXECUTE AS USER = 'GonzaloRodriguez';
EXEC Seguridad.GenerarNotaCredito_sp 2,60,6.25,'Palangana' ;
REVERT;

-- 8) Ejecutar hasta acá <--- ; Resultado esperado -> El usuario no tiene permisos

-- Ejecutamos como el usuario 'VladimirFrancisco', que posee rol "Supervisor",
-- y por lo tanto debe poder realizar notas de crédito
EXECUTE AS USER = 'VladimirFrancisco';
EXEC Seguridad.GenerarNotaCredito_sp 2,60,6.25,'Palangana' ;
REVERT;

SELECT * FROM Ventas.NotaCredito
-- 9) Ejecutar hasta acá <--- ; Resultado esperado -> Nota de Crédito insertada
