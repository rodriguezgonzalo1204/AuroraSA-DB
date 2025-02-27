----------PRUEBAS SP-----------

--------------------------------------------------------------------------------
--PRUEBAS DE SUCURSAL
--------------------------------------------------------------------------------
/* 
   InsertarSucursal_sp 
   - Se espera que inserte una nueva sucursal con los datos indicados.
*/
PRINT '=== InsertarSucursal_sp: Insertando Sucursal San Justo ===';
EXEC Personas.InsertarSucursal_sp
     @nombreSucursal = 'San Justo',
     @direccion      = 'Almafuerte 4450',
     @ciudad         = 'San Justo',
     @telefono       = '1588221136';
-- Resultado esperado: Se inserta correctamente la sucursal con activo = 1
select * from personas.sucursal
/* 
   ActualizarSucursal_sp
   - Se espera que actualice la sucursal con idSucursal = 1 (asumiendo que fue la que insertaste).
*/
PRINT '=== ActualizarSucursal_sp: Actualizando Sucursal (id=1) ===';
EXEC Personas.ActualizarSucursal_sp
     @idSucursal     = 1,
     @nombreSucursal = 'San Justo Nueva',
     @direccion      = 'ALmafuerte 4450',
     @ciudad         = 'San Justo',
     @telefono       = '1588221234';
-- Resultado esperado: Se actualizan los datos de la sucursal id=1

/*
   EliminarSucursal_sp
   - Se espera que se marque como inactiva (activo = 0) la sucursal con id=2 (que no existe aún, por ejemplo).
*/
PRINT '=== EliminarSucursal_sp: Intentando eliminar Sucursal (id=2, inexistente) ===';
EXEC Personas.EliminarSucursal_sp
     @idSucursal = 2;
-- Resultado esperado: RAISERROR


--------------------------------------------------------------------------------
--PRUEBAS DE EMPLEADO
--------------------------------------------------------------------------------

/*
   InsertarEmpleado_sp
   - Insertamos un empleado en la sucursal con id=1.
*/
PRINT '=== InsertarEmpleado_sp: Insertando Empleado en Empleado (id=1) ===';
EXEC Personas.InsertarEmpleado_sp
     @nombre     = 'Juan',
     @apellido   = 'Perez',
     @domicilio  = 'Avellaneda 158',
     @telefono   = '1133558833',
     @CUIL       = '20457797841',
     @fechaAlta  = '2025-01-01',
	 @idSucursal = 1
-- Resultado esperado: Se inserta correctamente

/*
   ActualizarEmpleado_sp
   - Se espera que actualice el empleado cuyo "idSucursal" sea 1.
*/
PRINT '=== ActualizarEmpleado_sp: Actualizando Empleado (idEmpleado=1) ===';
EXEC Personas.ActualizarEmpleado_sp
	 @idEmpleado = 1,
     @nombre     = 'Juan Carlos',
     @apellido   = 'Perez',
     @domicilio  = 'Calle A 456',
     @telefono   = '0987654321',
     @CUIL       = '2012345678',
     @fechaAlta  = '2025-01-02',
	 @idSucursal = 1
-- Resultado esperado: Actualiza el registro del empleado que tiene idSucursal=1 
select * from personas.empleado
/*
   EliminarEmpleado_sp
   - Marcamos como inactivo al empleado que está en la sucursal id=1.
*/
PRINT '=== EliminarEmpleado_sp: Eliminando Empleado en Empleado (id=1) ===';
EXEC Personas.EliminarEmpleado_sp
     @idEmpleado = 1;
-- Resultado esperado: Se pone activo=0 al registro que tenga idSucursal=1
--                    (si existe).

--------------------------------------------------------------------------------
-- PRUEBAS DE CLIENTE
--------------------------------------------------------------------------------

/*
   InsertarCliente_sp
   - Tu definición de SP InsertarCliente_sp tiene un @idCliente como parámetro,
     lo cual es inusual porque la tabla tiene IDENTITY. 
     Pero mostraremos la prueba con tus parámetros.
*/
PRINT '=== InsertarCliente_sp: Insertando Cliente';
EXEC Personas.InsertarCliente_sp
     @nombre             = 'Ana',
     @apellido           = 'Lopez',
     @tipoCliente        = 'Activo',
     @genero             = 'F',
     @datosFidelizacion  = '2025-01-01';  -- asumiendo DATE en tu SP
-- Resultado esperado: Inserta el cliente en la tabla

/*
   ActualizarCliente_sp
   - Se actualiza el cliente con idCliente=1 (si existe).
*/
PRINT '=== ActualizarCliente_sp: Actualizando Cliente (idCliente=1) ===';
EXEC Personas.ActualizarCliente_sp
     @idCliente          = 1,
     @nombre             = 'Ana Maria',
     @apellido           = 'Lopez',
     @tipoCliente        = 'Normal',
     @genero             = 'F',
     @datosFidelizacion  = '2025-01-02';
-- Resultado esperado: Actualiza los datos del cliente 1. 

/*
   3.3. EliminarCliente_sp
   - Se elimina lógicamente el cliente con idCliente=1.
*/
PRINT '=== EliminarCliente_sp: Eliminando Cliente (idCliente=1) ===';
EXEC Personas.EliminarCliente_sp
     @idCliente = 5;
-- Resultado esperado: Da error

--------------------------------------------------------------------------------
-- PRUEBAS DE PRODUCTO
--------------------------------------------------------------------------------

/*
   InsertarProducto_sp
*/
PRINT '=== InsertarProducto_sp: Insertando Producto ===';
EXEC Catalogos.InsertarProducto_sp
     @nombreProducto = 'Leche entera',
     @lineaProducto  = 'Bebidas',
     @marca          = 'Asturiana',
     @precioUnitario = 1.25;
-- Resultado esperado: Inserta un producto con activo=1

/*
   ActualizarProducto_sp
*/
PRINT '=== ActualizarProducto_sp: Actualizando Producto (idProducto=1) ===';
EXEC Catalogos.ActualizarProducto_sp
     @idProducto     = 1,
     @nombreProducto = 'Leche descremada',
     @lineaProducto  = 'Bebidas',
     @marca          = 'Asturiana',
     @precioUnitario = 1.30;
-- Resultado esperado: Actualiza el producto id=1

/*
   EliminarProducto_sp
   - Borrado lógico del producto id=1
*/
PRINT '=== EliminarProducto_sp: Eliminando Producto (idProducto=1) ===';
EXEC Catalogos.EliminarProducto_sp
     @idProducto = 1;
-- Resultado esperado: pone activo=0 en el producto id=1

--------------------------------------------------------------------------------
-- PRUEBAS DE FACTURA
--------------------------------------------------------------------------------

/*
   InsertarFactura_sp
   - Insertamos una factura para el cliente=1 (si sigue activo),
     empleado=1, sucursal=1. Ajusta el idEmpleado según tu tabla.
*/
PRINT '=== InsertarFactura_sp: Insertando Factura ===';
EXEC Ventas.InsertarFactura_sp
     @tipoFactura  = 'A',
     @fecha        = '2025-01-10',
     @hora         = '10:30:00',
     @idMedioPago  = 'MercadoPago',
     @idCliente    = 1,
     @idEmpleado   = 1,   
     @idSucursal   = 1;
-- Resultado esperado: Inserta una nueva factura con activo=1

/*
   ActualizarFactura_sp
*/
PRINT '=== ActualizarFactura_sp: Actualizando Factura (idFactura=1) ===';
EXEC Ventas.ActualizarFactura_sp
     @idFactura    = 1,
     @tipoFactura  = 'C',
     @fecha        = '2025-01-11',
     @hora         = '11:45:00',
     @idMedioPago  = 'Efectivo',
     @idCliente    = 1,
     @idEmpleado   = 1,
     @idSucursal   = 1;
-- Resultado esperado: Actualiza la factura id=1

/*
   5.3. EliminarFactura_sp
   - Borrado lógico de la factura id=1
*/
PRINT '=== EliminarFactura_sp: Eliminando Factura (idFactura=1) ===';
EXEC Ventas.EliminarFactura_sp
     @idFactura = 1;

--------------------------------------------------------------------------------
-- PRUEBAS DE DETALLEVENTA
--------------------------------------------------------------------------------

/*
   InsertarDetalleVenta_sp
   - Insertamos un detalle de venta en la factura=1 y producto=1
*/
PRINT '=== InsertarDetalleVenta_sp: Insertando detalle en Factura=1, Producto=1 ===';
EXEC Ventas.InsertarDetalleVenta_sp
     @idFactura      = 1,
     @idProducto     = 1,
     @cantidad       = 5,
     @precioUnitario = 1.25;
-- Resultado esperado: Inserta un registro en DetalleVenta con subtotal= 5 * 1.25 = 6.25

/*
   ActualizarDetalleVenta_sp
   - Actualizamos el detalle con idDetalle=1 (asumiendo que fue el primero insertado).
*/
PRINT '=== ActualizarDetalleVenta_sp: Actualizando detalle (idDetalle=1) ===';
EXEC Ventas.ActualizarDetalleVenta_sp
     @idDetalle      = 1,
     @idProducto     = 1,
     @cantidad       = 7,
     @precioUnitario = 1.20;
-- Resultado esperado: Cambia cantidad=7, precio=1.20 => subtotal= 7 * 1.20 = 8.40

/*
  EliminarDetalleVenta_sp
   - Borrado lógico del detalle con idDetalle=1
*/
PRINT '=== EliminarDetalleVenta_sp: Eliminando detalle (idDetalle=1) ===';
EXEC Ventas.EliminarDetalleVenta_sp
     @idDetalle = 1;
-- Resultado esperado: pone activo=0 en el detalle con idDetalle=1
