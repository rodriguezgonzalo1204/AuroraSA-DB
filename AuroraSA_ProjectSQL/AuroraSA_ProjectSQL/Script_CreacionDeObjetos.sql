/*
Aurora SA
Script de creacion de objetos. (Entrega 03)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/

------------CREACION DE DATABASE----------
Use master
GO
IF NOT EXISTS (SELECT NAME FROM master.dbo.sysdatabases WHERE NAME = 'Com1353G07')
BEGIN
    CREATE DATABASE Com1353G07
    COLLATE Modern_Spanish_CS_AS
END
ELSE
	print 'La base de datos ya existe.'
GO

Use Com1353G07
GO

------------CREACION DE ESQUEMAS----------
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name ='Empresa')
    EXEC('CREATE SCHEMA Empresa')
ELSE
    print 'El esquema Empresa ya existe en la base de datos.'
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Ventas')
    EXEC('CREATE SCHEMA Ventas')
ELSE
    print 'El esquema Ventas ya existe en la base de datos.'
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name ='Inventario')
    EXEC('CREATE SCHEMA Inventario')
ELSE 
    print 'El esquema Inventario ya existe en la base de datos.'
GO

-----------CREACION DE TABLAS------------

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Empresa' AND TABLE_NAME ='Sucursal')
BEGIN
CREATE TABLE Empresa.Sucursal
(
    idSucursal INT IDENTITY(1,1),
    nombreSucursal VARCHAR(30),
    direccion VARCHAR(50),
    ciudad VARCHAR(50),
    telefono CHAR(10),
	horario VARCHAR(55),
	activo BIT,
    CONSTRAINT PK_Sucursal PRIMARY KEY (idSucursal)
)
END
GO

/*
   Empleado: Contiene información del empleado y la sucursal a la que pertenece.
   Está en el esquema Empresa.
*/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Empresa' AND TABLE_NAME ='Empleado')
BEGIN
CREATE TABLE Empresa.Empleado
(
    idEmpleado INT IDENTITY(1,1),
    nombre VARCHAR(30),
    apellido VARCHAR(30),
	genero CHAR(1),
	cargo VARCHAR(25),
    domicilio VARCHAR(50),
    telefono CHAR(10),
    CUIL CHAR(10),
    fechaAlta DATE,
	mailEmpresa VARCHAR(55),
	mailPersonal VARCHAR(55),
    idSucursal INT,
	activo BIT,
    CONSTRAINT PK_Empleado PRIMARY KEY (idEmpleado),
    CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY (idSucursal) REFERENCES Empresa.Sucursal(idSucursal)
)
END
GO

/*
   Cliente: Contiene datos del cliente, tipoCliente, género, etc.
   Está en el esquema Ventas.
*/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Ventas' AND TABLE_NAME ='Cliente')
BEGIN
CREATE TABLE Ventas.Cliente
(
    idCliente INT IDENTITY(1,1),
    nombre VARCHAR(30),
    apellido VARCHAR(30),
    tipoCliente VARCHAR(10),
    genero CHAR(1),
    datosFidelizacion int, 
    activo BIT,
    CONSTRAINT PK_Cliente PRIMARY KEY (idCliente)
)
END
GO

/*
	LineaProducto: Registra todas las lineas de producto existentes junto con su descripción.
	Está en el esquema Inventario
*/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Inventario' AND TABLE_NAME ='LineaProducto')
BEGIN
CREATE TABLE Inventario.LineaProducto
(
	idLineaProd INT IDENTITY(1,1),
	descripcion VARCHAR(30),
	activo bit,
	CONSTRAINT PK_LineaProducto PRIMARY KEY (idLineaProd)
)
END
GO

/*
   Producto: Contiene información de los productos (nombre, línea, precio, etc.).
   Está en el esquema Inventario.
*/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Inventario' AND TABLE_NAME ='Producto')
BEGIN
CREATE TABLE Inventario.Producto
(
    idProducto INT IDENTITY(1,1),
    nombreProducto NVARCHAR(60),
    marca VARCHAR(20),
    precioUnitario DECIMAL(10,2),
	lineaProducto INT,
	activo BIT,   
    CONSTRAINT PK_Producto PRIMARY KEY (idProducto),
	CONSTRAINT FK_Producto_LineaProducto FOREIGN KEY (lineaProducto) REFERENCES Inventario.LineaProducto(idLineaProd)
)
END
GO

/*
   Factura: Registra la venta general. Se asocia a un Cliente, Empleado, Sucursal, y un Medio de Pago (opcional).
   Está en el esquema Ventas.
*/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Ventas' AND TABLE_NAME ='Factura')
BEGIN
CREATE TABLE Ventas.Factura
(
    idFactura INT IDENTITY(1,1),
	codigoFactura CHAR(11),
	medioPago VARCHAR(20),
    tipoFactura CHAR(1),
    fecha DATE,
    hora TIME(0),
    identificadorPago varchar(25),
	total DECIMAL(10,2),
    idCliente INT,
    idEmpleado INT,
    idSucursal INT,
 	activo BIT,     
    CONSTRAINT PK_Factura PRIMARY KEY (idFactura),
    CONSTRAINT FK_Factura_Cliente FOREIGN KEY (idCliente) REFERENCES Ventas.Cliente (idCliente),
    CONSTRAINT FK_Factura_Empleado FOREIGN KEY (idEmpleado) REFERENCES Empresa.Empleado (idEmpleado),
    CONSTRAINT FK_Factura_Sucursal FOREIGN KEY (idSucursal) REFERENCES Empresa.Sucursal(idSucursal)   
)
END
GO

/*
   DetalleVenta: Registra el detalle de productos vendidos en cada Factura. Se identifica
   Está en el esquema Ventas.
*/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA ='Ventas' AND TABLE_NAME ='DetalleVenta')
BEGIN
CREATE TABLE Ventas.DetalleVenta
(
	idFactura INT,
    idDetalle INT,
    idProducto INT,
    cantidad INT,
	subtotal DECIMAL(10,2),
	precioUnitario DECIMAL(10,2),
    CONSTRAINT PK_DetalleVenta PRIMARY KEY (idDetalle,idFactura),
    CONSTRAINT FK_DetalleVenta_Factura FOREIGN KEY (idFactura) REFERENCES Ventas.Factura(idFactura),
    CONSTRAINT FK_DetalleVenta_Producto FOREIGN KEY (idProducto) REFERENCES Inventario.Producto (idProducto)
)
END
GO
