/*
Aurora SA
Script de creacion de stored procedures. (Entrega 03)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Francisco Vladimir (46030072) - Vuono Gabriel (42134185)
*/

---- CREACION DE SP -> INSERCION, ACTUALIZACION, BORRADO ----

Use Com1353G07
GO


------------------------------- FUNCIONES DE UTILIDAD -------------------------------------------
-- Validar que el teléfono sea un número de 10 dígitos y solo contenga caracteres numéricos
CREATE OR ALTER FUNCTION Utilidades.ValidarTelefono(@telefono VARCHAR(20))
RETURNS BIT
AS
BEGIN
    IF @telefono LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        RETURN 1;
    RETURN 0;
END;
GO

-- Validar el formato del CUIL (XX-XXXXXXXX-X)
CREATE OR ALTER FUNCTION Utilidades.ValidarCuil(@cuil VARCHAR(13))
RETURNS BIT
AS
BEGIN
	IF	@cuil LIKE '2[0347]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]' OR
		@cuil LIKE '3[034]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'
        RETURN 1;
    RETURN 0;
END;
GO

-- Validar formato de email 
CREATE OR ALTER FUNCTION Utilidades.ValidarEmail(@email VARCHAR(255))
RETURNS BIT
AS
BEGIN
    IF @email LIKE '_%@_%._%' 
        RETURN 1;
    RETURN 0;
END;
GO

-- Validar género (Solo M o F)
CREATE OR ALTER FUNCTION Utilidades.ValidarGenero(@genero CHAR(1))
RETURNS BIT
AS
BEGIN
    IF @genero IN ('M', 'F')
        RETURN 1;
    RETURN 0;
END;
GO



----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.InsertarSucursal_sp
(
    @direccion       NVARCHAR(100),
    @ciudad          VARCHAR(50),
    @telefono        CHAR(10),
    @horario         VARCHAR(55)	
)
AS
BEGIN
    SET NOCOUNT ON;

	-- Verificacion de longitud de numero telefonico
	IF Utilidades.ValidarTelefono(@telefono) = 0
	BEGIN
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
		RETURN;
	END;
   
	INSERT INTO Empresa.Sucursal 
    (
        direccion,
        ciudad,
        telefono,
	horario
    )
    VALUES
    (
        @direccion,
        @ciudad,
        @telefono,
	@horario
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.ActualizarSucursal_sp
(
    @idSucursal      INT,
    @direccion       NVARCHAR(100),
    @ciudad          VARCHAR(50),
    @telefono        CHAR(10),
    @horario         VARCHAR(55)	
)
AS
BEGIN
    SET NOCOUNT ON;

	-- Verificacion sucursal existente
    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal)
    BEGIN    
		RAISERROR('No existe la sucursal indicada.', 16, 1);
		RETURN;
	END

    IF Utilidades.ValidarTelefono(@telefono) = 0
	BEGIN
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
		RETURN;
	END

    UPDATE Empresa.Sucursal
    SET
        direccion      = @direccion,
        ciudad         = @ciudad,
        telefono       = @telefono,
	horario	       = @horario
WHERE idSucursal = @idSucursal;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.EliminarSucursal_sp
(
    @idSucursal INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
	BEGIN
        RAISERROR('No existe la sucursal indicada.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Empresa.Sucursal
    SET activo = 0
    WHERE idSucursal = @idSucursal;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.InsertarEmpleado_sp
(
<<<<<<< HEAD
	@idEmpleado		INT,
    @nombre			VARCHAR(30),
=======
    @nombre		VARCHAR(30),
>>>>>>> f09b5c3f6ba508ef5c6d0d395b906f3ab0527df8
    @apellido		VARCHAR(30),
    @genero		CHAR(1),
    @cargo		VARCHAR(25),
    @domicilio		NVARCHAR(100),
    @telefono		CHAR(10),
    @cuil		CHAR(13),
    @fechaAlta		DATE,
    @mailPersonal	VARCHAR(55),
    @mailEmpresa	VARCHAR(55),
    @idSucursal		INT,
    @turno		VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

	-- Verificacion formato de cuil
	IF Utilidades.ValidarCuil(@cuil) = 0
	BEGIN
		RAISERROR('Formato de cuil inválido.',16,1)
		RETURN;
	END
	
	IF EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado)
    BEGIN
		RAISERROR('Ya existe un empleado con el legajo indicado.', 16, 1);
	END

	-- Verificacion genero
	IF Utilidades.ValidarGenero(@genero) = 0
	BEGIN
		RAISERROR('Género inválido.',16,1)
		RETURN;
	END
	
	IF Utilidades.ValidarGenero(@genero) = 0
	BEGIN
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
		RETURN;
	END

	-- Verificacion formato de mail
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
    END

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
		@domicilio,
		@telefono,
		@cuil,		
		@fechaAlta,	
		@mailPersonal,
		@mailEmpresa,
		@idSucursal,
		@turno
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.ActualizarEmpleado_sp
(	
    @idEmpleado		INT,
    @nombre		VARCHAR(30),
    @apellido		VARCHAR(30),
    @genero		CHAR(1),
    @cargo		VARCHAR(25),
    @domicilio		NVARCHAR(100),
    @telefono		CHAR(10),
    @cuil		CHAR(13),
    @fechaAlta		DATE,
    @mailPersonal	VARCHAR(55),
    @mailEmpresa	VARCHAR(55),
    @idSucursal		INT,
    @turno		VARCHAR(20)
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
		RAISERROR('Formato de cuil inválido.',16,1)
		RETURN;
	END

	IF Utilidades.ValidarGenero(@genero) = 0
	BEGIN
		RAISERROR('Genero inválido',16,1)
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

	IF Utilidades.ValidarEmail(@mailPersonal) = 0
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
        nombre	     = @nombre,
        apellido     = @apellido,
	genero	     = @genero,
	cargo	     = @cargo,
        domicilio    = @domicilio,
        telefono     = @telefono,
	cuil	     = @cuil,
	fechaAlta    = @fechaAlta,
	mailPersonal = @mailPersonal,
	mailEmpresa  = @mailEmpresa, 
	idSucursal   = @idSucursal,
	turno	     = @turno
    WHERE idEmpleado = @idEmpleado;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.EliminarEmpleado_sp
(
    @idEmpleado INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
	BEGIN
        RAISERROR('No existe el empleado.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Empresa.Empleado
    SET activo = 0
    WHERE idEmpleado = @idEmpleado;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.InsertarCliente_sp
(
    @nombre			VARCHAR(30),
    @apellido			VARCHAR(30),
    @tipoCliente		VARCHAR(10),
    @genero			CHAR(1),
    @datosFidelizacion		INT
)AS
BEGIN
    SET NOCOUNT ON;
    
	IF Utilidades.ValidarGenero(@genero) = 0
	BEGIN
		RAISERROR('Género inválido.',16,1)
		RETURN;
	END

	INSERT INTO Ventas.Cliente
    (
        nombre,
        apellido,
        tipoCliente,
        genero,
	datosFidelizacion
    )
    VALUES
    (
	@nombre,	
	@apellido,
	@tipoCliente,
	@genero,		
	@datosFidelizacion
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ActualizarCliente_sp
(
    @idCliente			INT,
    @nombre			VARCHAR(30),
    @apellido			VARCHAR(30),
    @tipoCliente		VARCHAR(10),
    @genero			CHAR(1),
    @datosFidelizacion		INT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE idCliente = @idCliente AND activo = 1)
	BEGIN
        RAISERROR('No existe el cliente.', 16, 1);
		RETURN;
	END

    IF Utilidades.ValidarGenero(@genero) = 0
	BEGIN
		RAISERROR('Género inválido.',16,1) 
		RETURN;
	END

    UPDATE Ventas.Cliente
    SET
        nombre				= @nombre,
        apellido			= @apellido,
        tipoCliente			= @tipoCliente,
	genero				= @genero,
	datosFidelizacion		= @datosFidelizacion
    WHERE idCliente = @idCliente;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.EliminarCliente_sp
(
    @idCliente INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE idCliente = @idCliente AND activo = 1)
	BEGIN
        RAISERROR('No existe el cliente.', 16, 1);
		RETURN;
	END

    -- Borrado lógico
    UPDATE Ventas.Cliente
    SET activo = 0
    WHERE idCliente = @idCliente;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.InsertarProducto_sp
(
    @nombreProducto   NVARCHAR(100),
    @precioUnitario   DECIMAL(10,2),
    @lineaProducto    INT
)
AS
BEGIN
    SET NOCOUNT ON;

	--Verificar linea de producto
	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE idLineaProd = @lineaProducto AND activo = 1)
	BEGIN
		RAISERROR('Linea de producto inexistente.', 16, 1);
		RETURN;
	END

	-- Verificar nombre válido
	IF @nombreProducto IS NULL OR LEN(@nombreProducto) = 0
	BEGIN
        RAISERROR('El nombre del producto es obligatorio.', 16, 1);
		RETURN;
	END
   
   -- Verificar precio mayor a cero
    IF @precioUnitario <= 0
	BEGIN
        RAISERROR('El precio unitario debe ser mayor a 0.', 16, 1);
     	RETURN;
	END

    INSERT INTO Inventario.Producto
    (
        nombreProducto,
        precioUnitario,
	lineaProducto
    )
    VALUES
    (
        @nombreProducto,
        @precioUnitario,
	@lineaProducto 
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.ActualizarProducto_sp
(
    @idProducto       INT,
    @nombreProducto   NVARCHAR(100),
    @lineaProducto    VARCHAR(20),
    @precioUnitario   DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar que el producto exista
    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE idProducto = @idProducto AND activo = 1)
	BEGIN
        RAISERROR('No existe el producto indicado.', 16, 1);
		RETURN;
	END

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE idLineaProd = @lineaProducto AND activo = 1)
	BEGIN
		RAISERROR('Linea de producto inexistente.', 16, 1);
		RETURN;
	END

	IF @nombreProducto IS NULL OR LEN(@nombreProducto) = 0
	BEGIN
        RAISERROR('El nombre del producto es obligatorio.', 16, 1);
		RETURN;
	END

    IF @precioUnitario <= 0
	BEGIN
        RAISERROR('El precio unitario debe ser mayor a 0.', 16, 1);
		RETURN;
	END
	
    UPDATE Inventario.Producto
    SET
        nombreProducto  = @nombreProducto,
        lineaProducto   = @lineaProducto,
        precioUnitario  = @precioUnitario
    WHERE idProducto = @idProducto;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.EliminarProducto_sp
(
    @idProducto INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE idProducto = @idProducto AND activo = 1)
	BEGIN
        RAISERROR('No existe el producto indicado.', 16, 1);
		RETURN;
	END
      
    UPDATE Inventario.Producto
    SET activo = 0
    WHERE idProducto = @idProducto;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.InsertarFactura_sp
(
    @codigoFactura		CHAR(11),
	@tipoFactura		CHAR(1),
    @fecha				DATE,
    @hora				VARCHAR(15),
    @medioPago			VARCHAR(20),
	@identificadorPago  VARCHAR(35),
	@total				DECIMAL (10,2),
	@idCliente		    INT,
    @idEmpleado			INT,
    @idSucursal			INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar tipo de factura
    IF @tipoFactura NOT IN ('A','B','C')
	BEGIN
        RAISERROR('Tipo de factura inválido (use A, B o C).', 16, 1);
		RETURN;
	END

	-- Validar cliente, empleado y sucursal existentes
    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE idCliente = @idCliente AND activo = 1)
	BEGIN
		RAISERROR('El cliente no existe o no está activo.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
	BEGIN
        RAISERROR('El empleado no existe o no está activo.', 16, 1);
		RETURN;
	END       
    
	IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
	BEGIN
        RAISERROR('La sucursal no existe o no está activa.', 16, 1);
		RETURN;
	END

	-- Validar metodos de pago validos
    IF @medioPago NOT IN ('Credit card', 'Cash', 'Ewallet')
	BEGIN
		RAISERROR('Metodo de pago inexistente.',16,1);
		RETURN;
	END
	
	-- Validar formato de codigo de factura
    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Formato de codigo de factura inválido.',16,1);
		RETURN;
	END

    INSERT INTO Ventas.Factura
    (
        codigoFactura,
		tipoFactura,
        fecha,
        hora,
        medioPago,
		identificadorPago,
		total,
        idCliente,
        idEmpleado,
        idSucursal
    )
    VALUES
    (
        @codigoFactura,
		@tipoFactura,
        @fecha,
        @hora,
        @medioPago,
		@identificadorPago,
		@total,
        @idCliente,
        @idEmpleado,
        @idSucursal
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ActualizarFactura_sp
(
    @codigoFactura		CHAR(11),
	@tipoFactura		CHAR(1),
    @fecha				DATE,
    @hora				VARCHAR(15),
    @medioPago			VARCHAR(20),
	@identificadorPago  VARCHAR(35),
	@total				DECIMAL (10,2),
	@idCliente		    INT,
    @idEmpleado			INT,
    @idSucursal			INT,
	@idFactura			INT	
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @idFactura AND activo = 1)
	BEGIN
        RAISERROR('No existe la factura indicada.', 16, 1);
		RETURN;
	END

	IF @tipoFactura NOT IN ('A','B','C')
	BEGIN
        RAISERROR('Tipo de factura inválido (use A, B o C).', 16, 1);
     	RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE idCliente = @idCliente AND activo = 1)
	BEGIN
        RAISERROR('El cliente no existe o no está activo.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
	BEGIN
        RAISERROR('El empleado no existe o no está activo.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
	BEGIN
        RAISERROR('La sucursal no existe o no está activa.', 16, 1);
		RETURN;
	END

    IF @medioPago NOT IN ('Credit card', 'Cash', 'Ewallet')
	BEGIN
		RAISERROR('Metodo de pago inexistente',16,1);
		RETURN;
	END

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Formato de codigo de factura inválido',16,1);
		RETURN;
	END

    UPDATE Ventas.Factura
    SET
        codigoFactura	          = @codigoFactura,
	tipoFactura		  = @tipoFactura,
        fecha			  = @fecha,
        hora			  = @hora,
        medioPago		  = @medioPago,
	identificadorPago 	  = @identificadorPago,
	total			  = @total,
        idCliente		  = @idCliente,
        idEmpleado		  = @idEmpleado,
        idSucursal		  = @idSucursal
    WHERE idFactura		  = @idFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.EliminarFactura_sp
(
    @idFactura INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @idFactura)
	BEGIN
        RAISERROR('No existe la factura indicada.', 16, 1);
    	RETURN;
	END

    UPDATE Ventas.Factura
    SET activo = 0
    WHERE idFactura = @idFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.InsertarDetalleVenta_sp
(
    @idFactura       INT,
    @idProducto      INT,
    @cantidad        INT
)
AS
BEGIN
    SET NOCOUNT ON;

	-- Validar cantidad mayor a cero
	IF @cantidad <= 0
	BEGIN
        RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);
		RETURN;
	END

	-- Validar factura activa y existente
    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @idFactura AND activo = 1)
	BEGIN
        RAISERROR('La factura no existe o no está activa.', 16, 1);
		RETURN;
	END

	-- Validar producto existente
    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE idProducto = @idProducto AND activo = 1)
	BEGIN
        RAISERROR('El producto no existe o no está activo.', 16, 1);
		RETURN;
	END

	-- Guardado de precio del producto al momento de la factura
	DECLARE @precioUnitario DECIMAL(10,2) = (SELECT precioUnitario from Inventario.Producto WHERE idProducto = @idProducto);
	
	-- Crear el idDetalle para que sea consecutivo al ultimo numero correspondiente a la factura accedida 
	DECLARE @idDetalle INT;
    SET @idDetalle = ISNULL((SELECT MAX(idDetalle) FROM Ventas.DetalleVenta WHERE idFactura = @idFactura), 0) + 1;

    INSERT INTO Ventas.DetalleVenta
    (
        idFactura,
	idDetalle,
        idProducto,
        cantidad,
        precioUnitario,
        subtotal
    )
    VALUES
    (
        @idFactura,
	@idDetalle,
        @idProducto,
        @cantidad,
        @precioUnitario,
        (@cantidad * @precioUnitario)  -- Calculamos subtotal
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ActualizarDetalleVenta_sp
(
    @idFactura	     INT,
    @idDetalle       INT,
    @idProducto      INT,
    @cantidad        INT
)
AS
BEGIN
    SET NOCOUNT ON;

	-- Validar factura activa y existente
    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @idFactura AND activo = 1)
	BEGIN
        RAISERROR('La factura no existe o no está activa.', 16, 1);
		RETURN;
	END

	-- Validar detalle de factura
    IF NOT EXISTS (SELECT 1 FROM Ventas.DetalleVenta WHERE idDetalle = @idDetalle AND idFactura = @idFactura)
	BEGIN
        RAISERROR('No existe el detalle de venta de la factura indicada.', 16, 1);
		RETURN;
	END

	-- Validar cantidad mayor a cero
	IF @cantidad <= 0
	BEGIN
        RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);
		RETURN;
	END

	-- Validar producto existente
    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE idProducto = @idProducto AND activo = 1)
	BEGIN
        RAISERROR('El producto no existe o no está activo.', 16, 1);
		RETURN;
	END

	-- Guardado de precio del producto al momento de la factura
	DECLARE @precioUnitario DECIMAL(10,2) = (SELECT precioUnitario from Inventario.Producto WHERE idProducto = @idProducto);

    UPDATE Ventas.DetalleVenta
    SET
        idProducto     = @idProducto,
        cantidad       = @cantidad,
        precioUnitario = @precioUnitario,
        subtotal       = (@cantidad * @precioUnitario)
    WHERE
        idDetalle = @idDetalle AND idFactura = @idFactura
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.EliminarDetalleVenta_sp
(
    @idDetalle INT,
    @idFactura INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @idFactura AND activo = 1)
	BEGIN
        RAISERROR('La factura no existe o no está activa.', 16, 1);
		RETURN;
	END

    IF NOT EXISTS (SELECT 1 FROM Ventas.DetalleVenta WHERE idDetalle = @idDetalle AND idFactura = @idFactura)
	BEGIN
        RAISERROR('No existe el detalle de venta de la factura indicada.', 16, 1);
		RETURN;
	END

	DELETE FROM Ventas.DetalleVenta WHERE idFactura = @idFactura AND idDetalle = @idDetalle;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.InsertarLineaProducto_sp
(
    @descripcion VARCHAR(30)
)
AS
BEGIN
    SET NOCOUNT ON;

	IF @descripcion IS NULL OR LEN(@descripcion) = 0
	BEGIN
        RAISERROR('El nombre la linea de producto es obligatorio.', 16, 1);
		RETURN;
	END

	INSERT INTO Inventario.LineaProducto
	(
		descripcion
	)
	VALUES
	(
		@descripcion
	)
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.ActualizarLineaProducto_sp
(
	@idLineaProd INT,
    @descripcion VARCHAR(30)
)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE idLineaProd = @idLineaProd)
	BEGIN
		RAISERROR('Linea de producto inexistente.',16,1);
			RETURN;
	END

	IF @descripcion IS NULL OR LEN(@descripcion) = 0
	BEGIN
        RAISERROR('El nombre la linea de producto es obligatorio.', 16, 1);
		RETURN;
	END

	UPDATE Inventario.LineaProducto
	SET
	      descripcion = @descripcion
	WHERE idLineaProd = @idLineaProd;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.EliminarLineaProducto_sp
(
	@idLineaProd INT
)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE idLineaProd = @idLineaProd)
	BEGIN
		RAISERROR('Linea de producto inexistente.',16,1);
		RETURN;
	END

	UPDATE Inventario.LineaProducto
	SET activo = 0
	WHERE idLineaProd = @idLineaProd;
END;
GO

----------------------------------------------------------------------------------------------
-- Vacia todas las tablas y resetea los autoincrementales identity
CREATE OR ALTER PROCEDURE Utilidades.ResetearTablas_sp
AS
BEGIN
    SET NOCOUNT ON;

	-- Vaciar tablas
    DELETE FROM Ventas.DetalleVenta;
    DELETE FROM Ventas.Factura;
    DELETE FROM Ventas.Cliente;
    DELETE FROM Empresa.Empleado;
    DELETE FROM Empresa.Sucursal;
    DELETE FROM Inventario.Producto;
    DELETE FROM Inventario.LineaProducto;
    DELETE FROM Ventas.NotaCredito;
    
    -- Resetear los contadores de IDENTITY
    DBCC CHECKIDENT ('Ventas.Factura', RESEED, 0);
    DBCC CHECKIDENT ('Ventas.Cliente', RESEED, 0);
<<<<<<< HEAD
	DBCC CHECKIDENT ('Ventas.NotaCredito', RESEED, 0);
=======
    DBCC CHECKIDENT ('Ventas.NotaCredito', RESEED, 0);
    DBCC CHECKIDENT ('Empresa.Empleado', RESEED, 257019);
>>>>>>> f09b5c3f6ba508ef5c6d0d395b906f3ab0527df8
    DBCC CHECKIDENT ('Empresa.Sucursal', RESEED, 0);
    DBCC CHECKIDENT ('Inventario.Producto', RESEED, 0);
    DBCC CHECKIDENT ('Inventario.LineaProducto', RESEED, 0);
END;
GO
