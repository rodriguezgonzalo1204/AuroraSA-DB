/*
Aurora SA
Importacion de archivos maestros. (Entrega 04)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/

-----------------------------------------

USE Com1353G07
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'DynamicParameters', 1;
-- Ejecutar y seguir documentación para permitir la importación de archivos desde Excel .xlsx





-----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.CargarProductosCatalogoCSV_sp
    @rutaArchivo                NVARCHAR(250),
    @rutaArchivoEquivalencias   NVARCHAR(250),
    @valorDolar                 DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear tabla temporal para cargar los datos del CSV
    CREATE TABLE #TempProductos1 (
        id INT,
        category NVARCHAR(50),
        name NVARCHAR(110),  
        price DECIMAL(10,2),
        reference_price DECIMAL(10,2),
        reference_unit VARCHAR(10),
        date DATETIME
    );

    -- Crear tabla temporal para buscar coincidencias de línea de producto
    CREATE TABLE #TempEquivalenciaLineas (
        lineaNueva NVARCHAR(25),
        lineaVieja NVARCHAR(50)
    );

    -- SQL dinámico para importar el archivo CSV
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
    BULK INSERT #TempProductos1
    FROM ''' + @rutaArchivo + '''
    WITH (
        FORMAT = ''CSV'', 
        FIRSTROW = 2, 
        FIELDTERMINATOR = '','', 
        ROWTERMINATOR = ''0x0A'',
        CODEPAGE = ''65001'',
        TABLOCK
    );
    ';
    
    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

    -- SQL dinámico para importar el archivo de equivalencias de línea producto
    SET @sql = '
        INSERT INTO #TempEquivalenciaLineas (lineaNueva, lineaVieja)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivoEquivalencias + ''',
            ''SELECT * FROM [Clasificacion productos$B1:C149]'');
    ';
    EXEC sp_executesql @sql;

    -- Insertar las nuevas líneas de producto que no existen
    INSERT INTO Inventario.LineaProducto (descripcion)
    SELECT DISTINCT E.lineaNueva
    FROM #TempEquivalenciaLineas E
    LEFT JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion COLLATE Modern_Spanish_CS_AS
    WHERE LP.idLineaProd IS NULL;

    -- Insertar productos usando JOIN
    INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
    SELECT 
        P.name, 
        LP.idLineaProd, 
        P.price * @valorDolar
    FROM #TempProductos1 P
    INNER JOIN #TempEquivalenciaLineas E ON P.category = E.lineaVieja COLLATE Modern_Spanish_CS_AS
    INNER JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion COLLATE Modern_Spanish_CS_AS;

    -- Limpiar tablas temporales
    DROP TABLE #TempEquivalenciaLineas;
    DROP TABLE #TempProductos1;

    PRINT 'Importación completada correctamente.';
END;
GO

EXEC Inventario.CargarProductosCatalogoCSV_sp 'C:\Users\GVuono\OneDrive - AGT Networks\Escritorio\Nueva carpeta\catalogo.csv',1;
EXEC Inventario.CargarProductosCatalogoCSV_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\catalogo.csv',
											  'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx',1;

SELECT * FROM Inventario.Producto


-----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.CargarProductosElectronicos_sp
    @rutaArchivo NVARCHAR(250),
	@valorDolar DECIMAL(10,2)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @idLineaProd int = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = 'Electronico');

	-- Verifica si ya existe la linea de producto electrónico, sino existe la crea.
	IF @idLineaProd IS NULL
	BEGIN 
		EXEC Inventario.InsertarLineaProducto_sp 'Electronico'
		SET @idLineaProd = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = 'Electronico');
	END

    CREATE TABLE #TempProductos (
        nombre NVARCHAR(110),
        precio DECIMAL(10,2)
    );

    -- Insertar datos desde el archivo XLSX
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #TempProductos (Nombre, Precio)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''',
            ''SELECT * FROM [Sheet1$B1:C26]'');
    ';
	EXEC sp_executesql @sql
    
	-- Se insertan datos segun el precio del dolar y el id correspondiente de la linea electrónico
	INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
    SELECT 
        nombre AS nombre,
        @idLineaProd AS lineaProducto,          
        precio*@valorDolar AS precioUnitario               
    FROM #TempProductos;
    DROP TABLE #TempProductos;
END
GO

EXEC Inventario.CargarProductosElectronicos_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Electronic accessories.xlsx',1
SELECT * FROM Inventario.Producto

--------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Inventario.CargarProductosImportados_sp
    @rutaArchivo NVARCHAR(250),
	@valorDolar DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear tabla temporal para cargar los datos del CSV
    CREATE TABLE #TempProductos (
        idProducto INT,
        NombreProducto NVARCHAR(100),
        Proveedor NVARCHAR(100),
		Categoria NVARCHAR(30),
		CantidadPorUnidad VARCHAR(20),
        precioUnidad DECIMAL(10,2)
    );

	--DECLARE @rutaArchivo varchar(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Productos_importados.xlsx'
	

    -- Insertar datos desde el archivo XLSX
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #TempProductos (idProducto, NombreProducto, Proveedor, Categoria, CantidadPorUnidad, precioUnidad)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''',
            ''SELECT * FROM [Listado De Productos$]'');
    ';
	EXEC sp_executesql @sql
	
	UPDATE #TempProductos
	SET Categoria = CASE WHEN Categoria in ('Carnes','Frutas/Verduras','Pescado/Marisco') THEN  'Frescos'
						 WHEN Categoria in ('Condimentos','Granos/Cereales','Lácteos','Repostería') THEN 'Almacen'
						 ELSE Categoria
					END

    -- Insertar nuevas líneas de producto si no existen
    INSERT INTO Inventario.LineaProducto (descripcion)
    SELECT DISTINCT TP.Categoria
    FROM #TempProductos TP
    LEFT JOIN Inventario.LineaProducto LP ON TP.Categoria = LP.descripcion COLLATE Modern_Spanish_CS_AS
    WHERE LP.idLineaProd IS NULL;

    -- Insertar productos con join para optimizar
    INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
    SELECT TP.NombreProducto, LP.idLineaProd, TP.precioUnidad * @valorDolar
    FROM #TempProductos TP
    INNER JOIN Inventario.LineaProducto LP ON TP.Categoria = LP.descripcion COLLATE Modern_Spanish_CS_AS;

    DROP TABLE #TempProductos;
	PRINT 'Importación completada correctamente.';
END
GO

EXEC Inventario.CargarProductosImportados_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Productos_importados.xlsx',1
SELECT * FROM Inventario.Producto
SELECT * FROM Inventario.LineaProducto

-----------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Empresa.ImportarSucursales_sp
    @rutaArchivo NVARCHAR(250) 
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #TempSucursales ( 
		ciudad VARCHAR(30),
		direccion NVARCHAR(100),
		horario VARCHAR(55),
		telefono char(10)
    );

    DECLARE @sql NVARCHAR(MAX)
    SET @sql = '
        INSERT INTO #TempSucursales (ciudad, direccion, horario, telefono)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''',
            ''SELECT * FROM [sucursal$C2:F5]'');
    ';
    EXEC sp_executesql @sql

	INSERT INTO Empresa.Sucursal (direccion, ciudad, telefono, horario)
	SELECT direccion, ciudad, telefono, horario
	FROM #TempSucursales	

	DROP TABLE #TempSucursales

	PRINT 'Importación completada correctamente.';
END;
GO

EXEC Empresa.ImportarSucursales_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx';
SELECT * FROM Empresa.Sucursal
-----------------------------------------------------------------------------------------------
-- Funcion para CUIL random
CREATE OR ALTER FUNCTION Utilidades.GenerarCUIL(@dni INT)
RETURNS CHAR(13)
AS
BEGIN
    DECLARE @cuil CHAR(13)
    DECLARE @codigoVerificacion INT
    DECLARE @prefijo INT
    
    -- Generamos un valor aleatorio que solo puede ser 20 o 27
    IF (ABS(CHECKSUM(CURRENT_TIMESTAMP)) % 2) = 0
        SET @prefijo = 20
    ELSE
        SET @prefijo = 27
    
    -- Ultimo digito
    SET @codigoVerificacion = ABS(CHECKSUM(CURRENT_TIMESTAMP)) % 10

    -- Formatear
    SET @cuil = CAST(@prefijo AS VARCHAR(2)) + '-' + RIGHT('00000000' + CAST(@dni AS VARCHAR(10)), 8) + '-' + CAST(@codigoVerificacion AS VARCHAR(1))

    RETURN @cuil
END
GO

----------------------------
CREATE OR ALTER PROCEDURE Empresa.ImportarEmpleados_sp
    @rutaArchivo NVARCHAR(250) 
AS
BEGIN
    SET NOCOUNT ON -- apagar

    CREATE TABLE #TempEmpleados
    ( 
    nombre VARCHAR(30),
    apellido VARCHAR(30),
	dni	int,
	domicilio NVARCHAR(100),
	mailPersonal VARCHAR(55),
    mailEmpresa VARCHAR(55),
	cuil CHAR(13),
    cargo VARCHAR(25),
    ciudadSuc VARCHAR(30)
    )

    DECLARE @cadenaSql NVARCHAR(MAX)
    SET @cadenaSql = '
        INSERT INTO #TempEmpleados (nombre, apellido, dni, domicilio, mailPersonal, mailEmpresa, cuil, cargo, ciudadSuc)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''',
            ''SELECT * FROM [Empleados$B2:J17]'');
    ';
    EXEC sp_executesql @cadenaSql

	DECLARE @FechaInicio AS date,
			@FechaFin AS date,
			@DiasIntervalo AS int;

	SELECT	@FechaInicio   = '20220101',
			@FechaFin     = '20250227',
			@DiasIntervalo = (1+DATEDIFF(DAY, @FechaInicio, @FechaFin))
	--
	INSERT INTO Empresa.Empleado ( nombre, apellido, genero, cargo, domicilio, telefono, CUIL, fechaAlta, mailPersonal,mailEmpresa, idSucursal)
	SELECT 
        TE.nombre,
        TE.apellido,
        -- Género aleatorio (F/M)
        CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'F' ELSE 'M' END AS genero,
        TE.cargo,
        TE.domicilio,
        -- Teléfono aleatorio que comienza con 11 + 8 dígitos (Los '000000000' aseguran que siempre sean 8 digitos, y el RIGHT se queda solo con la parte derecha)
        '11' + RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR(8)), 8) AS telefono,
        Utilidades.GenerarCUIL(TE.dni),
		DATEADD(DAY, RAND(CHECKSUM(NEWID()))*@DiasIntervalo,@FechaInicio),
        TE.mailPersonal,
        TE.mailEmpresa,
        S.idSucursal
    FROM #TempEmpleados TE
    INNER JOIN Empresa.Sucursal S 
        ON TE.ciudadSuc = S.ciudad COLLATE Modern_Spanish_CS_AS;

	DROP TABLE #TempEmpleados
END;
GO

EXEC Empresa.ImportarEmpleados_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx'
SELECT * FROM Empresa.Empleado

--------------------------------------------------------------------------------
-- Carga masiva de clientes randoms
CREATE OR ALTER PROCEDURE Ventas.CargarClientesAleatorios_sp
	@cantidad int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Nombres TABLE (nombre VARCHAR(30));
    DECLARE @Apellidos TABLE (apellido VARCHAR(30));

    INSERT INTO @Nombres (nombre)
    VALUES 
        ('Juan'), ('María'), ('Carlos'), ('Ana'), ('Luis'),
        ('Laura'), ('Pedro'), ('Sofía'), ('Miguel'), ('Lucía'),
        ('Jorge'), ('Elena'), ('Diego'), ('Carmen'), ('Andrés'),
        ('Isabel'), ('Fernando'), ('Patricia'), ('Ricardo'), ('Rosa'),
        ('Gabriel'), ('Silvia'), ('José'), ('Adriana'), ('Martín'),
        ('Claudia'), ('Raúl'), ('Valeria'), ('Oscar'), ('Daniela');

    INSERT INTO @Apellidos (apellido)
    VALUES 
        ('Gómez'), ('Pérez'), ('García'), ('Rodríguez'), ('López'),
        ('Martínez'), ('Fernández'), ('González'), ('Sánchez'), ('Romero'),
        ('Díaz'), ('Torres'), ('Álvarez'), ('Ruiz'), ('Hernández'),
        ('Jiménez'), ('Moreno'), ('Muñoz'), ('Alonso'), ('Ortega');

    -- Insertar X cantidad de clientes aleatorios
    DECLARE @i INT = 0;
    WHILE @i < @cantidad
    BEGIN
        -- Seleccionar nombre y apellido aleatorio
        DECLARE @nombre VARCHAR(30), @apellido VARCHAR(30);
        SELECT TOP 1 @nombre = nombre FROM @Nombres ORDER BY NEWID();
        SELECT TOP 1 @apellido = apellido FROM @Apellidos ORDER BY NEWID();

        -- Generar tipoCliente y género aleatorio
        DECLARE @tipoCliente VARCHAR(10), @genero CHAR(1);
        SET @tipoCliente = CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'Member' ELSE 'Normal' END;
        SET @genero = CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'F' ELSE 'M' END;

        -- Insertar cliente
		EXEC Ventas.InsertarCliente_sp @nombre, @apellido, @tipoCliente, @genero, 0

        SET @i = @i +[Inventario].[Producto] 1;
    END;

    PRINT '100 clientes aleatorios cargados correctamente.';
END;
GO

EXEC Ventas.CargarClientesAleatorios_sp 100
SELECT * FROM Ventas.Cliente

--------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Ventas.ImportarVentas_sp
    @rutaArchivo NVARCHAR(250),
	@valorDolar DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear tabla temporal para cargar los datos del CSV
    CREATE TABLE #TempVentas (
        codigoFactura CHAR(11),
		tipoFactura CHAR(1),
		ciudad VARCHAR(20),
		tipoCliente VARCHAR(10),
		genero VARCHAR(10),
        nombreProducto NVARCHAR(100),
		precioUnitario DECIMAL(10,2),
		cantidad INT,
		fecha VARCHAR(10),
		hora VARCHAR(15),
		medioPago VARCHAR(20),
		idEmpleado INT,
		identificadorPago VARCHAR(35)
    );

  
    DECLARE @sql NVARCHAR(MAX);
	SET @sql = '
    BULK INSERT #TempVentas
    FROM ''' + @rutaArchivo + '''
    WITH (
        FORMAT = ''CSV'', 
        FIRSTROW = 2, 
        FIELDTERMINATOR = '';'', 
        ROWTERMINATOR = ''\n'',
        CODEPAGE = ''65001'',
        TABLOCK
    );
    ';
	EXEC sp_executesql @sql


	-- Actualizamos la ciudad con su respectivo remplazo
	UPDATE #TempVentas
    SET ciudad = CASE 
                    WHEN ciudad = 'Yangon' THEN 'San Justo'
                    WHEN ciudad = 'Naypyitaw' THEN 'Ramos Mejia'
                    WHEN ciudad = 'Mandalay' THEN 'Lomas del Mirador'
                    ELSE ciudad
                 END;

	CREATE TABLE #TotalesPorFactura (
		codigoFactura CHAR(11),
		total DECIMAL(10, 2) 
	);
	
	INSERT INTO #TotalesPorFactura (codigoFactura, total)
	SELECT CAST(codigoFactura AS CHAR(11)) as codigoFactura, SUM(precioUnitario * cantidad * @valorDolar) AS total
	FROM #TempVentas
	GROUP BY codigoFactura;

	INSERT INTO Ventas.Factura (codigoFactura, medioPago, tipoFactura, fecha, hora, identificadorPago, total, idCliente, idEmpleado, idSucursal)
	SELECT 
		CAST(V.codigoFactura AS CHAR(11)) AS codigoFactura,  
		V.medioPago, 
		V.tipoFactura, 
		CONVERT(DATE, V.fecha, 101) AS fecha, 
		V.hora, 
		CASE WHEN V.medioPago = 'Cash' THEN '--' ELSE V.identificadorPago END AS identificadorPago,
		TF.total,
		C.idCliente, 
		V.idEmpleado, 
		S.idSucursal
	FROM #TempVentas V 
		INNER JOIN #TotalesPorFactura TF 
			ON V.codigoFactura = TF.codigoFactura  
		CROSS APPLY (SELECT TOP 1 idCliente FROM Ventas.Cliente			-- Utilizamos CROSS APPLY para poder elegir un cliente aleatorio
					 WHERE genero = LEFT(V.genero,1) COLLATE Modern_Spanish_CS_AS  
					 AND tipoCliente = V.tipoCliente COLLATE Modern_Spanish_CS_AS 
					 ORDER BY NEWID()) C
		LEFT JOIN Empresa.Sucursal S 
			ON V.ciudad COLLATE Modern_Spanish_CS_AS = S.ciudad;

	CREATE TABLE #GruposDetalle (
		codigoFactura CHAR(11),
		idDetalle INT,
		nombreProd NVARCHAR(100),
		precioUnitario DECIMAL(10,2),
		cantidad INT,
		subtotal DECIMAL(10,2), 
	);

	INSERT INTO #GruposDetalle(codigoFactura, idDetalle, nombreProd, precioUnitario, cantidad, subtotal)
	SELECT  CAST(codigoFactura AS CHAR(11)) as codigoFactura,
			ROW_NUMBER() OVER(PARTITION BY codigoFactura ORDER BY codigoFactura) as idDetalle,
			nombreProducto, precioUnitario, cantidad, cantidad*precioUnitario as subtotal
	FROM #TempVentas
	
	select * from #GruposDetalle



	INSERT INTO Ventas.DetalleVenta (idFactura, idDetalle, idProducto, precioUnitario, cantidad, subtotal)
	SELECT F.idFactura, GT.idDetalle, CA.idProducto, GT.precioUnitario, GT.cantidad, GT.subtotal
	FROM #GruposDetalle GT 
		INNER JOIN Ventas.Factura F
		ON GT.codigoFactura = F.codigoFactura COLLATE Modern_Spanish_CS_AS
		CROSS APPLY (
			SELECT TOP 1 idProducto
			FROM Inventario.Producto P
			WHERE P.nombreProducto = GT.nombreProd COLLATE Modern_Spanish_CS_AS
			ORDER BY idProducto) CA;



	DROP TABLE #TempVentas;
	DROP TABLE #TotalesPorFactura
	DROP TABLE #GruposDetalle
	PRINT 'Importación completada correctamente.';
END
GO

EXEC Ventas.ImportarVentas_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Ventas_registradas.csv',1
SELECT * FROM Ventas.Factura

select * from Ventas.DetalleVenta


select * from Empresa.Empleado

    DELETE FROM Ventas.Factura;
    DBCC CHECKIDENT ('Ventas.Factura', RESEED, 0);