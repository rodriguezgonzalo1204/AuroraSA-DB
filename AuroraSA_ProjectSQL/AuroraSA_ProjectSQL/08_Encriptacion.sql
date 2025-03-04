/*
Aurora SA
Encriptacion de datos de empleado. (Entrega 05)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Francisco Vladimir (46030072) - Vuono Gabriel (42134185)
*/

/*
	El Script está pensado para ejecutarse en un solo bloque con F5
	Sin embargo, tiene la posibilidad de visualizar el antes y despues de la encriptación ejecutando las lineas comentadas
*/

USE Com1353G07
GO


-- VER ANTES DE ENCRIPTAR
-- SELECT * FROM Empresa.Empleado


-- Creamos procedure para encriptar los campos de los empleados
CREATE OR ALTER PROCEDURE Seguridad.EncriptarEmpleado_sp
	@fraseClave NVARCHAR(128)
AS 
BEGIN
	-- Agregamos los campos para encriptar
	ALTER TABLE Empresa.Empleado
	ADD cuil_encriptado VARBINARY(256),
		domicilio_encriptado VARBINARY(256),
		telefono_encriptado VARBINARY(256),
		mailPersonal_encriptado VARBINARY(256);

	-- Encriptación masiva para toda la tabla
	UPDATE Empresa.Empleado
		SET cuil_encriptado = EncryptByPassPhrase(@fraseClave, cuil, 1, CONVERT(VARBINARY, idEmpleado)),
			telefono_encriptado = EncryptByPassPhrase(@fraseClave, telefono, 1, CONVERT(VARBINARY, idEmpleado)),
			mailPersonal_encriptado = EncryptByPassPhrase(@fraseClave, mailPersonal, 1, CONVERT(VARBINARY, idEmpleado)),
			domicilio_encriptado = EncryptByPassPhrase(@fraseClave, domicilio, 1, CONVERT(VARBINARY, idEmpleado))

	-- Eliminamos los campos originales, quedandonos solo con los encriptados
	DROP INDEX ix_cuil ON Empresa.Empleado;

	ALTER TABLE Empresa.Empleado DROP CONSTRAINT UQ_Empleado_Cuil;

	ALTER TABLE Empresa.Empleado DROP COLUMN cuil, domicilio, telefono, mailPersonal;

	-- Renombramos las columnas (los procedures/scripts anteriores dejaran de funcionar)
	EXEC sp_rename 'Empresa.Empleado.cuil_encriptado', 'cuil', 'COLUMN';
	EXEC sp_rename 'Empresa.Empleado.domicilio_encriptado', 'domicilio', 'COLUMN';
	EXEC sp_rename 'Empresa.Empleado.telefono_encriptado', 'telefono', 'COLUMN';
	EXEC sp_rename 'Empresa.Empleado.mailPersonal_encriptado', 'mailPersonal', 'COLUMN'
END;
GO


CREATE OR ALTER PROCEDURE Seguridad.MostrarEmpleadoEncriptado_sp
	@fraseClave NVARCHAR(128)
AS
BEGIN
	SELECT 
		idEmpleado, nombre, apellido, genero, 
		CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, cuil, 1, CONVERT(VARBINARY, idEmpleado))) AS cuil,
		CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, domicilio, 1, CONVERT(VARBINARY, idEmpleado))) AS domicilio,
		CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, telefono, 1, CONVERT(VARBINARY, idEmpleado))) AS telefono,
		CONVERT(VARCHAR, DecryptByPassPhrase(@fraseClave, mailPersonal, 1, CONVERT(VARBINARY, idEmpleado))) AS mailPersonal,
		mailEmpresa, idSucursal, cargo, fechaAlta
	FROM Empresa.Empleado;
END;
GO


-- VER TABLA LUEGO DE ENCRIPTACIÓN MEDIANTE CLAVE
--EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'NoTeOlvidesElWhereEnElDeleteFrom'




-- A continuación se modifican los procedures de Inserción y Actualización para admitir cifrado (Eliminación se mantiene)

-- Edición del procedure Insertar con la lógica de cifrado aplicada
CREATE OR ALTER PROCEDURE Empresa.InsertarEmpleado_sp
(
    @clave         NVARCHAR(128),  
	@idEmpleado		INT,
    @nombre			VARCHAR(30),
    @apellido		VARCHAR(30),
    @genero			CHAR(1),
    @cargo			VARCHAR(25),
    @domicilio		NVARCHAR(100),
    @telefono		CHAR(10),
    @cuil			CHAR(13),
    @fechaAlta		DATE,
    @mailPersonal	VARCHAR(55),
    @mailEmpresa	VARCHAR(55),
    @idSucursal		INT,
    @turno			VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificación de validaciones (se asume que las funciones de validación siguen funcionando sobre el valor en texto)
    IF Utilidades.ValidarCuil(@cuil) = 0
    BEGIN
        RAISERROR('Formato de cuil inválido.',16,1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado)
    BEGIN
        RAISERROR('Ya existe un empleado con el legajo indicado.', 16, 1);
        RETURN;
    END

    IF Utilidades.ValidarGenero(@genero) = 0
    BEGIN
        RAISERROR('Género inválido.',16,1);
        RETURN;
    END

    IF Utilidades.ValidarTelefono(@telefono) = 0
    BEGIN
        RAISERROR('El formato de teléfono es inválido.', 16, 1);
        RETURN;
    END

    IF Utilidades.ValidarEmail(@mailPersonal) = 0
    BEGIN
        RAISERROR('El formato de mail personal es inválido.', 16, 1);
        RETURN;
    END

    IF Utilidades.ValidarEmail(@mailEmpresa) = 0
    BEGIN
        RAISERROR('El formato de mail de la empresa es inválido.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
    BEGIN
        RAISERROR('No existe la sucursal indicada.', 16, 1);
        RETURN;
    END

    -- Insertar encriptando los campos sensibles
    INSERT INTO Empresa.Empleado
    (
		idEmpleado,
        nombre,
        apellido,
        genero,
        cargo,
        domicilio,
        telefono,
        cuil,
        fechaAlta,
        mailPersonal,
        mailEmpresa,
        idSucursal,
        turno
    )
    VALUES
    (
		@idEmpleado,
		@nombre,	
		@apellido,
		@genero,
		@cargo,
		EncryptByPassPhrase(@clave, @domicilio, 1, CONVERT(VARBINARY, @idEmpleado)),
		EncryptByPassPhrase(@clave, @telefono, 1, CONVERT(VARBINARY, @idEmpleado)),
		EncryptByPassPhrase(@clave, @cuil, 1, CONVERT(VARBINARY, @idEmpleado)),
		@fechaAlta,
		EncryptByPassPhrase(@clave, @mailPersonal, 1, CONVERT(VARBINARY, @idEmpleado)),
		@mailEmpresa,
		@idSucursal,
		@turno
    );
END;
GO

-- Edición del procedure Actualizar con la lógica de cifrado aplicada
CREATE OR ALTER PROCEDURE Empresa.ActualizarEmpleado_sp
(	
    @clave         NVARCHAR(128),  -- Nueva clave para encriptar
    @idEmpleado		INT,
    @nombre			VARCHAR(30),
    @apellido		VARCHAR(30),
    @genero			CHAR(1),
    @cargo			VARCHAR(25),
    @domicilio		NVARCHAR(100),
    @telefono		CHAR(10),
    @cuil			CHAR(13),
    @fechaAlta		DATE,
    @mailPersonal	VARCHAR(55),
    @mailEmpresa	VARCHAR(55),
    @idSucursal		INT,
    @turno			VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
    BEGIN
        RAISERROR('No existe el empleado.', 16, 1);
        RETURN;
    END

    IF Utilidades.ValidarCuil(@cuil) = 0
    BEGIN
        RAISERROR('Formato de cuil inválido.',16,1);
        RETURN;
    END

    IF Utilidades.ValidarGenero(@genero) = 0
    BEGIN
        RAISERROR('Género inválido.',16,1);
        RETURN;
    END

    IF Utilidades.ValidarTelefono(@telefono) = 0
    BEGIN
        RAISERROR('El formato de teléfono es inválido.', 16, 1);
        RETURN;
    END

    IF Utilidades.ValidarEmail(@mailPersonal) = 0
    BEGIN
        RAISERROR('El formato de mail personal es inválido.', 16, 1);
        RETURN;
    END

    IF Utilidades.ValidarEmail(@mailEmpresa) = 0
    BEGIN
        RAISERROR('El formato de mail de la empresa es inválido.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
    BEGIN
        RAISERROR('No existe la sucursal indicada.', 16, 1);
        RETURN;
    END

    UPDATE Empresa.Empleado
    SET
        nombre                = @nombre,
        apellido              = @apellido,
        genero                = @genero,
        cargo                 = @cargo,
        domicilio			  = EncryptByPassPhrase(@clave, @domicilio, 1, CONVERT(VARBINARY, @idEmpleado)),
        telefono			  = EncryptByPassPhrase(@clave, @telefono, 1, CONVERT(VARBINARY, @idEmpleado)),
        cuil				  = EncryptByPassPhrase(@clave, @cuil, 1, CONVERT(VARBINARY, @idEmpleado)),
        fechaAlta             = @fechaAlta,
        mailPersonal		  = EncryptByPassPhrase(@clave, @mailPersonal, 1, CONVERT(VARBINARY, @idEmpleado)),
        mailEmpresa           = @mailEmpresa,
        idSucursal            = @idSucursal,
        turno                 = @turno
    WHERE idEmpleado = @idEmpleado;
END;
GO