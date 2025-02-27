/*
Aurora SA
Script de creacion de stored procedures. (Entrega 03)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/

---- CREACION DE SP -> INCERSION, ACTUALIZACION, BORRADO ----

Use Com1353G07
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.InsertarSucursal_sp
(
    @nombreSucursal  VARCHAR(30),
    @direccion       VARCHAR(30),
    @ciudad          VARCHAR(50),
    @telefono        CHAR(10),
	@horario		 VARCHAR(55)	
)
AS
BEGIN
    SET NOCOUNT ON;
    IF (len(@telefono) <> 10)
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
   
	INSERT INTO Empresa.Sucursal 
    (
        nombreSucursal,
        direccion,
        ciudad,
        telefono,
		horario,
        activo
    )
    VALUES
    (
        @nombreSucursal,
        @direccion,
        @ciudad,
        @telefono,
		@horario,
        1  -- Por defecto activo = 1
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.ActualizarSucursal_sp
(
    @idSucursal      INT,
    @nombreSucursal  VARCHAR(30),
    @direccion       VARCHAR(30),
    @ciudad          VARCHAR(50),
    @telefono        CHAR(10),
	@horario		 VARCHAR(55)	
)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal)
        RAISERROR('No existe la sucursal indicada.', 16, 1);

    IF (len(@telefono) <> 10)
		RAISERROR('El formato de teléfono es inválido.', 16, 1);
   
    UPDATE Empresa.Sucursal
    SET
        nombreSucursal = @nombreSucursal,
        direccion      = @direccion,
        ciudad         = @ciudad,
        telefono       = @telefono,
		horario		   = @horario
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

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal)
        RAISERROR('No existe la sucursal indicada.', 16, 1);

    -- Borrado lógico
    UPDATE Empresa.Sucursal
    SET activo = 0
    WHERE idSucursal = @idSucursal;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.InsertarEmpleado_sp
(
    @nombre			VARCHAR(30),
    @apellido		VARCHAR(30),
	@genero			CHAR(1),
	@cargo			VARCHAR(25),
    @domicilio		VARCHAR(50),
    @telefono		CHAR(10),
    @CUIL			CHAR(10),
    @fechaAlta		DATE,
	@mailPersonal	VARCHAR(55),
	@mailEmpresa	VARCHAR(55),
    @idSucursal		INT
)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT (@CUIL LIKE '[23,24,27,30,33,34]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]')
		RAISERROR('Formato de CUIL inválido',16,1)

	IF @genero NOT IN ('F', 'M')
		RAISERROR('Genero inválido',16,1)
    
	IF (len(@telefono) <> 10)
		RAISERROR('El formato de teléfono es inválido.', 16, 1);

	IF NOT @mailPersonal LIKE '_%@_%._%'
		RAISERROR('El formato de mail personal es inválido.', 16, 1);

	IF NOT @mailEmpresa LIKE '_%@_%._%'
		RAISERROR('El formato de mail de la empresa es inválido.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
        RAISERROR('No existe la sucursal indicada.', 16, 1);

    INSERT INTO Empresa.Empleado
    (
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
		activo
    )
    VALUES
    (
		@nombre,	
		@apellido,
		@genero,
		@cargo,
		@domicilio,
		@telefono,
		@CUIL,		
		@fechaAlta,	
		@mailPersonal,
		@mailEmpresa,
		@idSucursal,
        1
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.ActualizarEmpleado_sp
(
    @nombre			VARCHAR(30),
    @apellido		VARCHAR(30),
	@genero			CHAR(1),
	@cargo			VARCHAR(25),
    @domicilio		VARCHAR(50),
    @telefono		CHAR(10),
    @CUIL			CHAR(10),
    @fechaAlta		DATE,
	@mailPersonal	VARCHAR(55),
	@mailEmpresa	VARCHAR(55),
    @idSucursal		INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Personas.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
        RAISERROR('No existe el empleado.', 16, 1);

	IF NOT (@CUIL LIKE '[23,24,27,30,33,34]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]')
		RAISERROR('Formato de CUIL inválido',16,1)

	IF @genero NOT IN ('F', 'M')
		RAISERROR('Genero inválido',16,1)
    
	IF (len(@telefono) <> 10)
		RAISERROR('El formato de teléfono es inválido.', 16, 1);

	IF NOT @mailPersonal LIKE '_%@_%._%'
		RAISERROR('El formato de mail personal es inválido.', 16, 1);

	IF NOT @mailEmpresa LIKE '_%@_%._%'
		RAISERROR('El formato de mail de la empresa es inválido.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
        RAISERROR('No existe la sucursal indicada.', 16, 1);
    
    UPDATE Empresa.Empleado
    SET
        nombre		 = @nombre,
        apellido     = @apellido,
		genero		 = @genero,
		cargo		 = @cargo,
        domicilio    = @domicilio,
        telefono     = @telefono,
		CUIL		 = @CUIL,
		fechaAlta	 = @fechaAlta,
		mailPersonal = @mailPersonal,
		mailEmpresa  = @mailEmpresa, 
		idSucursal	 = @idSucursal
    WHERE idEmpleado = @idEmpleado;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Empresa.EliminarEmpleado_sp
(
    @idEmpleado INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
        RAISERROR('No existe el empleado.', 16, 1);

    -- Borrado lógico
    UPDATE Personas.Empleado
    SET activo = 0
    WHERE idEmpleado = @idEmpleado;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.InsertarCliente_sp
(
    @nombre				VARCHAR(30),
    @apellido			VARCHAR(30),
    @tipoCliente		VARCHAR(10),
    @genero				CHAR(1),
    @datosFidelizacion	INT
)AS
BEGIN
    SET NOCOUNT ON;
    
	IF @genero NOT IN ('F', 'M')
		RAISERROR('Genero inválido',16,1)

	INSERT INTO Ventas.Cliente
    (
        nombre,
        apellido,
        tipoCliente,
        genero,
		datosFidelizacion,
		activo
    )
    VALUES
    (
		@nombre,	
		@apellido,
		@tipoCliente,
		@genero,		
		@datosFidelizacion,	
        1
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ActualizarCliente_sp
(
    @idCliente			INT,
    @nombre				VARCHAR(30),
    @apellido			VARCHAR(30),
    @tipoCliente		VARCHAR(10),
    @genero				CHAR(10),
    @datosFidelizacion	INT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE idCliente = @idCliente and activo = 1)
        RAISERROR('No existe el cliente.', 16, 1);
      
    IF @genero NOT IN ('F', 'M')
		RAISERROR('Genero inválido',16,1) 

    UPDATE Ventas.Cliente
    SET
        nombre				= @nombre	,
        apellido			= @apellido,
        tipoCliente			= @tipoCliente,
		genero				= @genero	,
		datosFidelizacion	= @datosFidelizacion
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
        RAISERROR('No existe el cliente.', 16, 1);
 
    -- Borrado lógico
    UPDATE Ventas.Cliente
    SET activo = 0
    WHERE idCliente = @idCliente;
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.InsertarProducto_sp
(
    @nombreProducto   NVARCHAR(60),
    @marca            VARCHAR(20),
    @precioUnitario   DECIMAL(10,2),
	@lineaProducto    INT
)
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE idLineaProd = @lineaProducto AND activo = 1)
		RAISERROR('Linea de producto inexistente.', 16, 1);

	IF @nombreProducto IS NULL OR LEN(@nombreProducto) = 0
        RAISERROR('El nombre del producto es obligatorio.', 16, 1);
   
    IF @precioUnitario <= 0
        RAISERROR('El precio unitario debe ser mayor a 0.', 16, 1);
     

    INSERT INTO Inventario.Producto
    (
        nombreProducto,
        marca,
        precioUnitario,
		lineaProducto,
        activo
    )
    VALUES
    (
        @nombreProducto,
        @marca,
        @precioUnitario,
		@lineaProducto,
        1 
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.ActualizarProducto_sp
(
    @idProducto       INT,
    @nombreProducto   NVARCHAR(60),
    @lineaProducto    VARCHAR(20),
    @marca            VARCHAR(20),
    @precioUnitario   DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar que el producto exista
    IF NOT EXISTS (SELECT 1 FROM Inventario.Producto WHERE idProducto = @idProducto AND activo = 1)
        RAISERROR('No existe el producto indicado.', 16, 1);

	IF NOT EXISTS (SELECT 1 FROM Inventario.LineaProducto WHERE idLineaProd = @lineaProducto AND activo = 1)
		RAISERROR('Linea de producto inexistente.', 16, 1);

	IF @nombreProducto IS NULL OR LEN(@nombreProducto) = 0
        RAISERROR('El nombre del producto es obligatorio.', 16, 1);
   
    IF @precioUnitario <= 0
        RAISERROR('El precio unitario debe ser mayor a 0.', 16, 1);
    
    UPDATE Inventario.Producto
    SET
        nombreProducto  = @nombreProducto,
        lineaProducto   = @lineaProducto,
        marca           = @marca,
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
        RAISERROR('No existe el producto indicado.', 16, 1);
      
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
    @hora				TIME(0),
    @medioPago			VARCHAR(20),
	@identificadorPago  VARCHAR(25),
	@total				DECIMAL (10,2),
	@idCliente		    INT,
    @idEmpleado			INT,
    @idSucursal			INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @tipoFactura NOT IN ('A','B','C')
        RAISERROR('Tipo de factura inválido (use A, B o C).', 16, 1);
     
    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE idCliente = @idCliente AND activo = 1)
        RAISERROR('El cliente no existe o no está activo.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
        RAISERROR('El empleado no existe o no está activo.', 16, 1);
       
    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
        RAISERROR('La sucursal no existe o no está activa.', 16, 1);

    IF @medioPago NOT IN ('Credit card', 'Cash', 'Ewallet')
		RAISERROR('Metodo de pago inexistente',16,1);

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
		RAISERROR('Formato de codigo de factura inválido',16,1);

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
        idSucursal,
        activo
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
        @idSucursal,
        1
    );
END;
GO
----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ActualizarFactura_sp
(
    @codigoFactura		CHAR(11),
	@tipoFactura		CHAR(1),
    @fecha				DATE,
    @hora				TIME(0),
    @medioPago			VARCHAR(20),
	@identificadorPago  VARCHAR(25),
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
        RAISERROR('No existe la factura indicada.', 16, 1);
	
	IF @tipoFactura NOT IN ('A','B','C')
        RAISERROR('Tipo de factura inválido (use A, B o C).', 16, 1);
     
    IF NOT EXISTS (SELECT 1 FROM Ventas.Cliente WHERE idCliente = @idCliente AND activo = 1)
        RAISERROR('El cliente no existe o no está activo.', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM Empresa.Empleado WHERE idEmpleado = @idEmpleado AND activo = 1)
        RAISERROR('El empleado no existe o no está activo.', 16, 1);
       
    IF NOT EXISTS (SELECT 1 FROM Empresa.Sucursal WHERE idSucursal = @idSucursal AND activo = 1)
        RAISERROR('La sucursal no existe o no está activa.', 16, 1);

    IF @medioPago NOT IN ('Credit card', 'Cash', 'Ewallet')
		RAISERROR('Metodo de pago inexistente',16,1);

    IF @codigoFactura NOT LIKE ('[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]')
		RAISERROR('Formato de codigo de factura inválido',16,1);

    UPDATE Ventas.Factura
    SET
        codigoFactura	  = @codigoFactura,
		tipoFactura		  = @tipoFactura,
        fecha			  = @fecha,
        hora			  = @hora,
        medioPago		  = @medioPago,
		identificadorPago = @identificadorPago,
		total			  = @total,
        idCliente		  = @idCliente,
        idEmpleado		  = @idEmpleado,
        idSucursal		  = @idSucursal
    WHERE idFactura		  = @idFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.EliminarFactura_sp
(
    @idFactura INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @idFactura)
        RAISERROR('No existe la factura indicada.', 16, 1);
    
    UPDATE Ventas.Factura
    SET activo = 0
    WHERE idFactura = @idFactura;
END;
GO
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.InsertarDetalleVenta_sp
(
    @idFactura       INT,
    @idProducto      INT,
    @cantidad        INT,
    @precioUnitario  DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

	--validaciones
	    IF @cantidad <= 0
    BEGIN
        RAISERROR('La cantidad debe ser mayor a 0.', 16, 1);
        RETURN;
    END;

    IF @precioUnitario <= 0
    BEGIN
        RAISERROR('El precio unitario debe ser mayor a 0.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Ventas.Factura WHERE idFactura = @idFactura AND activo = 1)
    BEGIN
        RAISERROR('La factura no existe o no está activa.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Catalogos.Producto WHERE idProducto = @idProducto AND activo = 1)
    BEGIN
        RAISERROR('El producto no existe o no está activo.', 16, 1);
        RETURN;
    END;

    INSERT INTO Ventas.DetalleVenta
    (
        idFactura,
        idProducto,
        cantidad,
        precioUnitario,
        subtotal,
        activo
    )
    VALUES
    (
        @idFactura,
        @idProducto,
        @cantidad,
        @precioUnitario,
        (@cantidad * @precioUnitario),  -- Calculamos subtotal
        1
    );
END;
----------------------------------------------------------------------------------------------
CREATE PROCEDURE Ventas.ActualizarDetalleVenta_sp
(
    @idDetalle       INT,
    @idProducto      INT,
    @cantidad        INT,
    @precioUnitario  DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.DetalleVenta WHERE idDetalle = @idDetalle)
    BEGIN
        RAISERROR('No existe el detalle de venta indicado.', 16, 1);
        RETURN;
    END;

    UPDATE Ventas.DetalleVenta
    SET
        idProducto     = @idProducto,
        cantidad       = @cantidad,
        precioUnitario = @precioUnitario,
        subtotal       = (@cantidad * @precioUnitario)
    WHERE
        idDetalle = @idDetalle;
END;

CREATE PROCEDURE Ventas.EliminarDetalleVenta_sp
(
    @idDetalle INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Ventas.DetalleVenta WHERE idDetalle = @idDetalle)
    BEGIN
        RAISERROR('No existe el detalle de venta indicado.', 16, 1);
        RETURN;
    END;

    UPDATE Ventas.DetalleVenta
    SET activo = 0
    WHERE idDetalle = @idDetalle;
END;
----------------------------------------------------------------------------------------------