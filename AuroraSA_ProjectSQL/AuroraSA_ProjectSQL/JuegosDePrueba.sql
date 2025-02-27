/*
Aurora SA
Juego de Preubas para Store Precedures de manipulacion de objetos. (Entrega 03)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/

----------PRUEBAS SP-----------
RAISERROR('Debe ejecutar el script siguiendo las indicaciones comentadas.',16,1)

-- Utilizar la DB
USE Com1353G07
GO

-- RESETEAR AUTOINCREMENTALES Y VACIAR TABLAS 
EXEC ResetearTablas_sp
GO
-- Ejecutar hasta aca

--------------------------------------------------------------------------------
--PRUEBAS DE SUCURSAL
--------------------------------------------------------------------------------
/* 
	--------------------
	InsertarSucursal_sp 
	--------------------
*/
PRINT '=== InsertarSucursal_sp: Insertando Sucursal San Justo y Ramos Mejia ===';
EXEC Empresa.InsertarSucursal_sp
     @nombreSucursal = 'San Justo',
     @direccion      = 'Almafuerte 4450',
     @ciudad         = 'San Justo',
     @telefono       = '1588221136',
	 @horario		 = 'L a V 8 a. m. – 9 p. m.' 

EXEC Empresa.InsertarSucursal_sp 'Ramos Mejia', 'Alsina 23', 'Buenos Aires', '1542787454', 'L a V 8 a. m. – 9 p. m.';

SELECT * FROM Empresa.Sucursal
--Ejecutar hasta aca: Resultado esperado -> Se inserta correctamente la sucursal San Justo y Buenos Aires

PRINT '=== InsertarSucursal_sp: Error de número de teléfono ===';
EXEC Empresa.InsertarSucursal_sp
     @nombreSucursal = 'San Justo',
     @direccion      = 'Almafuerte 4450',
     @ciudad         = 'San Justo',
     @telefono       = '1111',
	 @horario		 = 'L a V 8 a. m. – 9 p. m.' 
--Ejecutar hasta aca: Resultado esperado -> Error número de teléfono inválido

/*
	--------------------
	ActualizarSucursal_sp
	--------------------
*/
PRINT '=== ActualizarSucursal_sp: Actualizando Sucursal (id=1) ===';
EXEC Empresa.ActualizarSucursal_sp
     @idSucursal     = 1,
     @nombreSucursal = 'San Justo Nueva',
     @direccion      = 'ALmafuerte 4450',
     @ciudad         = 'San Justo',
     @telefono       = '1588221234',
	 @horario		 =  'L a V 8 a. m. – 9 p. m';
SELECT * FROM Empresa.Sucursal
-- Ejecutar hasta aca: Resultado esperado -> Se actualizan los datos de la sucursal id=1

/*
	--------------------
	EliminarSucursal_sp
	--------------------
*/
PRINT '=== EliminarSucursal_sp: Intentando eliminar Sucursal (id=4, inexistente) ===';
EXEC Empresa.EliminarSucursal_sp
     @idSucursal = 4;
-- Ejecutar hasta aca: Resultado esperado -> Error sucursal inexistente


--------------------------------------------------------------------------------
--PRUEBAS DE EMPLEADO
--------------------------------------------------------------------------------
/*
	--------------------
	InsertarEmpleado_sp
	--------------------
*/
PRINT '=== InsertarEmpleado_sp: Insertando Empleados en Empleado (id=1) y (id=2) ===';
EXEC Empresa.InsertarEmpleado_sp
     @nombre		= 'Juan',
     @apellido		= 'Perez',
	 @genero		= 'M',
	 @cargo			= 'Cajero',
     @domicilio		= 'Avellaneda 158',
     @telefono		= '1133558833',
     @CUIL			= '20-46415848-2',
     @fechaAlta		= '2025-01-01',
	 @mailPersonal	= 'Rolando_LOPEZ@gmail.com',
	 @mailEmpresa	= 'Rolando.LOPEZ@superA.com',
	 @idSucursal	= 1;

EXEC Empresa.InsertarEmpleado_sp 'Franco', 'Colapinto', 'M', 'Cajero','Calle234','1522441542','20-38652541-5','2024-08-09','FC@gmail.com','FC@SuperA.com',2
SELECT * FROM Empresa.Empleado
-- Ejecutar hasta aca: Resultado esperado -> Se inserta correctamente el empleado Juan Perez y Franco Colapinto


PRINT '=== InsertarEmpleado_sp: Intentando insertar empleado con CUIL Inválido ===';
EXEC Empresa.InsertarEmpleado_sp
     @nombre		= 'Juan',
     @apellido		= 'Perez',
	 @genero		= 'M',
	 @cargo			= 'Cajero',
     @domicilio		= 'Avellaneda 158',
     @telefono		= '1133558833',
     @CUIL			= '20333332', --Formato incorrecto
     @fechaAlta		= '2025-01-01',
	 @mailPersonal	= 'Rolando_LOPEZ@gmail.com',
	 @mailEmpresa	= 'Rolando.LOPEZ@superA.com',
	 @idSucursal	= 1;
-- Ejecutar hasta aca: Resultado esperado -> Error de CUIL

PRINT '=== InsertarEmpleado_sp: Intentando insertar empleado con mail Inválido ===';
EXEC Empresa.InsertarEmpleado_sp
     @nombre		= 'Juan',
     @apellido		= 'Perez',
	 @genero		= 'M',
	 @cargo			= 'Cajero',
     @domicilio		= 'Avellaneda 158',
     @telefono		= '1133558833',
     @CUIL			= '20-46415848-2',
     @fechaAlta		= '2025-01-01',
	 @mailPersonal	= 'Rolando_LOPE',  --Formato incorrecto
	 @mailEmpresa	= 'Rolando.LOPEZ@superA.com',
	 @idSucursal	= 1;
-- Ejecutar hasta aca: Resultado esperado -> Error de formato de mail

/*
	--------------------
	ActualizarEmpleado_sp
	--------------------  
*/
PRINT '=== ActualizarEmpleado_sp: Actualizando Empleado (idEmpleado=1) ===';
EXEC Empresa.ActualizarEmpleado_sp
	 @idEmpleado	= 1,
     @nombre		= 'Juan Carlos',
     @apellido		= 'Perez',
	 @genero		= 'M',
	 @cargo			= 'Cajero',
     @domicilio		= 'Calle A 456',
     @telefono		= '0987654321',
     @CUIL			= '20-46415848-2',
     @fechaAlta		= '2025-01-01',
	 @mailPersonal	= 'Rolando_LOPEZ@gmail.com',
	 @mailEmpresa	= 'Rolando.LOPEZ@superA.com',
	 @idSucursal	= 1
SELECT * FROM Empresa.Empleado
-- Ejecutar hasta aca: Resultado esperado -> Actualiza el registro del empleado que tiene idEmpleado = 1

/*
	--------------------
	EliminarEmpleado_sp
	--------------------
*/
PRINT '=== EliminarEmpleado_sp: Eliminando Empleado en Empleado (id=1) ===';
EXEC Empresa.EliminarEmpleado_sp
     @idEmpleado = 1;
SELECT * FROM Empresa.Empleado
-- Ejecutar hasta aca: Resultado esperado -> Borra (borrado logico) el empleado con id 1

--------------------------------------------------------------------------------
-- PRUEBAS DE CLIENTE
--------------------------------------------------------------------------------

/*
	--------------------
	InsertarCliente_sp
	--------------------
*/
PRINT '=== InsertarCliente_sp: Insertando Clientes ====';
EXEC Ventas.InsertarCliente_sp
     @nombre             = 'Ana',
     @apellido           = 'Lopez',
     @tipoCliente        = 'Member',
     @genero             = 'F',
     @datosFidelizacion  = '0';

EXEC Ventas.InsertarCliente_sp 'Pepe', 'Argento', 'Normal', 'M',0;
SELECT * FROM Ventas.Cliente
-- Ejecutar hasta aca: Resultado esperado -> Inserta el cliente Ana y cliente Pepe

PRINT '=== InsertarCliente_sp: Insertando Cliente con género inválido ====';
EXEC Ventas.InsertarCliente_sp
     @nombre             = 'Martin',
     @apellido           = 'Gimenez',
     @tipoCliente        = 'Member',
     @genero             = 'J',
     @datosFidelizacion  = '0';
-- Ejecutar hasta aca: Resultado esperado -> Error género inválido

/*
	--------------------
	ActualizarCliente_sp
	--------------------
*/
PRINT '=== ActualizarCliente_sp: Actualizando Cliente (idCliente=1) ===';
EXEC Ventas.ActualizarCliente_sp
     @idCliente          = 1,
     @nombre             = 'Ana Maria',
     @apellido           = 'Lopez',
     @tipoCliente        = 'Normal',
     @genero             = 'F',
     @datosFidelizacion  = '500';
SELECT * FROM Ventas.Cliente
-- Ejecutar hasta aca: Resultado esperado -> Actualiza los datos del cliente id=1

/*
	--------------------
	EliminarCliente_sp
	--------------------   
*/
PRINT '=== EliminarCliente_sp: Eliminando Cliente (idCliente=1) ===';
EXEC Ventas.EliminarCliente_sp
     @idCliente = 9;
-- Ejecutar hasta aca: Resultado esperado -> Error cliente inexistente

--------------------------------------------------------------------------------
-- PRUEBAS DE LINEA PRODUCTO
-------------------------------------------------------------------------------
/*
	--------------------------
	InsertarLineaDeProducto_sp
	--------------------------
*/
PRINT '=== InsertarLineaProducto_sp: Insertando tres lineas de productos ===';
EXEC Inventario.InsertarLineaProducto_sp 'Almacen'
EXEC Inventario.InsertarLineaProducto_sp 'Perfumeria'
EXEC Inventario.InsertarLineaProducto_sp 'Congelados'
SELECT * FROM Inventario.LineaProducto
-- Ejecutar hasta aca: Resultado esperado -> Inserta las tres lineas de productos correctamente

PRINT '=== InsertarLineaProducto_sp: Intentando insertar linea sin nombre ===';
EXEC Inventario.InsertarLineaProducto_sp ''
-- Ejecutar hasta aca: Resultado esperado -> Error linea sin nombre

--------------------------------------------------------------------------------
-- PRUEBAS DE PRODUCTO
--------------------------------------------------------------------------------
/*
	-------------------
	InsertarProducto_sp
	-------------------
*/
PRINT '=== InsertarProducto_sp: Insertando Productos ===';
EXEC Inventario.InsertarProducto_sp
     @nombreProducto = 'Leche entera',
     @lineaProducto  =  1,
     @marca          = 'Sancor',
     @precioUnitario = 1.25;

EXEC Inventario.InsertarProducto_sp 'Aceite', 'Marolio', 3.1, 1;
SELECT * FROM Inventario.Producto
-- Ejecutar hasta aca: Resultado esperado -> Inserta los productos Aceite y Leche correctamente

PRINT '=== InsertarProducto_sp: Intentando insertar producto con precio negativo ===';
EXEC Inventario.InsertarProducto_sp
     @nombreProducto = 'Leche descremada',
     @lineaProducto  =  1,
     @marca          = 'Sancor',
     @precioUnitario = -1.25;
-- Ejecutar hasta aca: Resultado esperado -> Error de precio

PRINT '=== InsertarProducto_sp: Intentando insertar producto con linea de producto inválida ===';
EXEC Inventario.InsertarProducto_sp
     @nombreProducto = 'Leche entera',
     @lineaProducto  =  9,
     @marca          = 'Sancor',
     @precioUnitario = 1.25;
-- Ejecutar hasta aca: Resultado esperado -> Error de linea de producto inexistente


/*
	----------------------
	ActualizarProducto_sp
	----------------------
*/
PRINT '=== ActualizarProducto_sp: Actualizando Producto (idProducto=1) ===';
EXEC Inventario.ActualizarProducto_sp
     @idProducto     = 1,
     @nombreProducto = 'Leche descremada',
     @lineaProducto  = 1,
     @marca          = 'Sancor',
     @precioUnitario = 2.45;
SELECT * FROM Inventario.Producto
-- Ejecutar hasta aca: Resultado esperado -> Actualiza el producto con id=1

/*
	-------------------
	EliminarProducto_sp
	-------------------
*/
PRINT '=== EliminarProducto_sp: Eliminando Producto (idProducto=1) ===';
EXEC Inventario.EliminarProducto_sp
     @idProducto = 3;
SELECT * FROM Inventario.Producto
-- Ejecutar hasta aca: Resultado esperado -> Borrado logico de producto con id = 1

--------------------------------------------------------------------------------
-- PRUEBAS DE FACTURA
--------------------------------------------------------------------------------

/*
	-------------------
	InsertarFactura_sp
	-------------------
*/
PRINT '=== InsertarFactura_sp: Insertando Facturas ===';
EXEC Ventas.InsertarFactura_sp
	 @codigoFactura		= '829-34-3910',
     @tipoFactura		= 'A',
     @fecha				= '2025-01-10',
     @hora				= '10:30:00',
     @medioPago			= 'Cash',
	 @identificadorPago = '',
	 @total				= 200,
     @idCliente			= 1,
     @idEmpleado		= 2,   
     @idSucursal		= 1;

EXEC Ventas.InsertarFactura_sp '754-22-4105','B','2025-02-05', '09:36:00', 'Cash', '', 900, 2, 2, 2;
SELECT * FROM Ventas.Factura
-- Ejecutar hasta aca: Resultado esperado -> Se insertan facturas 1 y 2 correspondientes a cliente 1 y 2, sucursal 1 y 2

PRINT '=== InsertarFactura_sp: Intentando insertar factura para empleado inexistente ===';
EXEC Ventas.InsertarFactura_sp
	 @codigoFactura		= '829-34-3910',
     @tipoFactura		= 'A',
     @fecha				= '2025-01-10',
     @hora				= '10:30:00',
     @medioPago			= 'Cash',
	 @identificadorPago = '',
	 @total				= 200,
     @idCliente			= 1,
     @idEmpleado		= 1,   
     @idSucursal		= 1;
-- Ejecutar hasta aca: Resultado esperado -> Error empleado inactivo

PRINT '=== InsertarFactura_sp: Insertando Factura ===';
EXEC Ventas.InsertarFactura_sp
	 @codigoFactura		= '22222', 
     @tipoFactura		= 'A',
     @fecha				= '2025-01-10',
     @hora				= '10:30:00',
     @medioPago			= 'Cash',
	 @identificadorPago = '',
	 @total				= 1,
     @idCliente			= 1,
     @idEmpleado		= 2,   
     @idSucursal		= 1;
-- Ejecutar hasta aca: Resultado esperado -> Error formato de codigo de factura

PRINT '=== InsertarFactura_sp: Insertando Factura ===';
EXEC Ventas.InsertarFactura_sp
	 @codigoFactura		= '829-34-3910',
     @tipoFactura		= 'A',
     @fecha				= '2025-01-10',
     @hora				= '10:30:00',
     @medioPago			= 'Dolares cara chica',
	 @identificadorPago = '',
	 @total				= 200,
     @idCliente			= 1,
     @idEmpleado		= 2,   
     @idSucursal		= 1;
-- Ejecutar hasta aca: Resultado esperado -> Error medio de pago inexistente

PRINT '=== InsertarFactura_sp: Insertando Factura ===';
EXEC Ventas.InsertarFactura_sp
	 @codigoFactura		= '829-34-3910',
     @tipoFactura		= 'Z',
     @fecha				= '2025-01-10',
     @hora				= '10:30:00',
     @medioPago			= 'Cash',
	 @identificadorPago = '',
	 @total				= 200,
     @idCliente			= 1,
     @idEmpleado		= 2,   
     @idSucursal		= 1;
-- Ejecutar hasta aca: Resultado esperado -> Error tipo de factura inválido

/*
	-------------------
	ActualizarFactura_sp
	-------------------
*/
PRINT '=== ActualizarFactura_sp: Actualizando Factura (idFactura=1) ===';
EXEC Ventas.ActualizarFactura_sp
     @idFactura			= 1,
	 @codigoFactura		= '829-34-3910',
     @tipoFactura		= 'C',
     @fecha				= '2025-01-11',
     @hora				= '11:45:00',
     @medioPago			= 'Cash',
	 @identificadorPago = '',
	 @total				= 400,
     @idCliente			= 1,
     @idEmpleado		= 2,
     @idSucursal		= 1;
SELECT * FROM Ventas.Factura
-- Ejecutar hasta aca: Resultado esperado -> Actualiza factura id=1

/*
	------------------
	EliminarFactura_sp
	------------------
*/
PRINT '=== EliminarFactura_sp: Eliminando Factura (idFactura=1) ===';
EXEC Ventas.EliminarFactura_sp
     @idFactura = 1;
SELECT * FROM Ventas.Factura
-- Ejecutar hasta aca: Resultado esperado -> Borra logicamente la factura id = 1

--------------------------------------------------------------------------------
-- PRUEBAS DE DETALLEVENTA
--------------------------------------------------------------------------------
/*
	----------------------
	InsertarDetalleVenta_sp
	----------------------
*/
PRINT '=== InsertarDetalleVenta_sp: Insertando detalles en Factura=2, Producto=1 y Producto=2 ===';
EXEC Ventas.InsertarDetalleVenta_sp
     @idFactura      = 2,
     @idProducto     = 1,
     @cantidad       = 5;

EXEC Ventas.InsertarDetalleVenta_sp 2,2,3;
SELECT * FROM Ventas.DetalleVenta
-- Ejecutar hasta aca: Resultado esperado -> Carga los detalles con el precio de los productos y calcula subtotal

PRINT '=== InsertarDetalleVenta_sp: Insertando detalle en Factura=10 ===';
EXEC Ventas.InsertarDetalleVenta_sp
     @idFactura      = 10,
     @idProducto     = 1,
     @cantidad       = 5;
-- Ejecutar hasta aca: Resultado esperado -> Error de factura inexistente

/*
	-------------------------
	ActualizarDetalleVenta_sp
	-------------------------
*/
PRINT '=== ActualizarDetalleVenta_sp: Actualizando detalle (idDetalle=1) ===';
EXEC Ventas.ActualizarDetalleVenta_sp
	 @idFactura		 = 2,
     @idDetalle      = 1,
     @idProducto     = 1,
     @cantidad       = 7;
SELECT * FROM Ventas.DetalleVenta
-- Ejecutar hasta aca: Resultado esperado -> Cambia cantidad=7, recalcula el subtotal

/*
	----------------------
	EliminarDetalleVenta_sp
	----------------------   
*/
PRINT '=== EliminarDetalleVenta_sp: Eliminando detalle (idDetalle=2) ===';
EXEC Ventas.EliminarDetalleVenta_sp
	 @idFactura = 2,
     @idDetalle = 2;
SELECT * FROM Ventas.DetalleVenta
-- Ejecutar hasta aca: Resultado esperado -> Elimina el detalle 2 de la factura 2

