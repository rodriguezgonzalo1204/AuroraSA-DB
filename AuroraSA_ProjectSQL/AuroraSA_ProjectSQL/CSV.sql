/*
Aurora SA
Importacion de archivos maestros. (Entrega 04)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/

-----------------------------------------


/*	
	Modo de ejecución
	El script esta pensado para poder ejecutarse de un solo bloque con F5 considerando que:
	1- Debe detallar la ruta del archivo previo a la importacion, asi como valor de dolar y cantidad de clientes random a generar
	2- Todas las tablas van a reiniciarse asi como los autoincrementales de las mismas
	3- Debe realizar previamente las configuraciones que se detallan en la documentacion
*/

USE Com1353G07
GO

-- INDICAR LAS RUTAS CORRESPONDIENTES DE LOS ARCHIVOS, VALOR ACTUAL DEL DOLAR Y CANTIDAD DE CLIENTES RANDOM A GENERAR

DECLARE @rutaCatalogoCSV NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\catalogo.csv',
		@rutaElectronicos NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Electronic accessories.xlsx',
		@rutaImportados NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Electronic accessories.xlsx',
		@rutaVentas NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Ventas_registradas.csv',
		@rutaComplementario NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx',
		@valorDolar DECIMAL(10,2) = 1,
		@cantClientes INT = 100;


-- VACIAR TABLAS Y REESTABLECER IDENTITY
SET NOCOUNT ON;
EXEC Utilidades.ResetearTablas_sp

-- CAMBIAR PARAMETROS PARA PERMITIR IMPORTACION

EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'AllowInProcess', 1;
GO
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'DynamicParameters', 1;
GO




-----------------------------------------------------------------------------------------------
-- Importacion de catalogo.csv
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
    JOIN #TempEquivalenciaLineas E ON P.category = E.lineaVieja COLLATE Modern_Spanish_CS_AS
    JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion COLLATE Modern_Spanish_CS_AS;

    -- Limpiar tablas temporales
    DROP TABLE #TempEquivalenciaLineas;
    DROP TABLE #TempProductos1;

    PRINT 'Importación completada correctamente.';
END;
GO

EXEC Inventario.CargarProductosCatalogoCSV_sp @rutaCatalogo, @rutaComplemantario, @valorDolar
GO

-----------------------------------------------------------------------------------------------
-- Importacion de productos electronicos
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

EXEC Inventario.CargarProductosElectronicos_sp @rutaElectronicos, @valorDolar
GO

--------------------------------------------------------------------------------
-- Importacion de productos importados
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

EXEC Inventario.CargarProductosImportados_sp @rutaImportados,@valorDolar
GO
-----------------------------------------------------------------------------------------------
-- Importacion de sucursales
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

	--No es necesario modificar ningun dato
	INSERT INTO Empresa.Sucursal (direccion, ciudad, telefono, horario)
	SELECT direccion, ciudad, telefono, horario
	FROM #TempSucursales	

	DROP TABLE #TempSucursales
	PRINT 'Importación completada correctamente.';
END;
GO

EXEC Empresa.ImportarSucursales_sp @rutaComplementario;
GO

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

-----------------------------------------------------------------------------------------------
-- Importacion de empleados
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
    ciudadSuc VARCHAR(30),
	turno	VARCHAR(20)
    )

    DECLARE @cadenaSql NVARCHAR(MAX)
    SET @cadenaSql = '
        INSERT INTO #TempEmpleados (nombre, apellido, dni, domicilio, mailPersonal, mailEmpresa, cuil, cargo, ciudadSuc, turno)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''',
            ''SELECT * FROM [Empleados$B2:K17]'');
    ';
    EXEC sp_executesql @cadenaSql

	-- Variables para generar fecha random entre los limites establecidos
	DECLARE @FechaInicio AS date,
			@FechaFin AS date,
			@DiasIntervalo AS int;

	SELECT	@FechaInicio   = '20220101',
			@FechaFin     = '20250227',
			@DiasIntervalo = (1+DATEDIFF(DAY, @FechaInicio, @FechaFin))
	
	INSERT INTO Empresa.Empleado ( nombre, apellido, genero, cargo, domicilio, telefono, CUIL, fechaAlta, mailPersonal,mailEmpresa, idSucursal, turno)
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
        S.idSucursal,
		TE.turno
    FROM #TempEmpleados TE
    JOIN Empresa.Sucursal S 
        ON TE.ciudadSuc = S.ciudad COLLATE Modern_Spanish_CS_AS;

	DROP TABLE #TempEmpleados
END;
GO

EXEC Empresa.ImportarEmpleados_sp @rutaComplementario
GO

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

        SET @i = @i + 1;
    END;

    PRINT '100 clientes aleatorios cargados correctamente.';
END;
GO

EXEC Ventas.CargarClientesAleatorios_sp @cantClientes
GO

--------------------------------------------------------------------------------
-- Importacion de ventas
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
	
	-- Agrupamos por codigo de factura para calcular totales e insertar en la tabla factura con el id deseado
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
		JOIN #TotalesPorFactura TF 
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

	-- Utilizamos row_number para indicar cuantos detalles corresponden a una misma factura (Para el caso de Ventas.CSV es 1 item por factura por lo que no se ve reflejado el cambio)
	INSERT INTO #GruposDetalle(codigoFactura, idDetalle, nombreProd, precioUnitario, cantidad, subtotal)
	SELECT  CAST(codigoFactura AS CHAR(11)) as codigoFactura,
			ROW_NUMBER() OVER(PARTITION BY codigoFactura ORDER BY codigoFactura) as idDetalle,
			nombreProducto, precioUnitario, cantidad, cantidad*precioUnitario*@valorDolar as subtotal
	FROM #TempVentas

	INSERT INTO Ventas.DetalleVenta (idFactura, idDetalle, idProducto, precioUnitario, cantidad, subtotal)
	SELECT F.idFactura, GT.idDetalle, CA.idProducto, GT.precioUnitario, GT.cantidad, GT.subtotal
	FROM #GruposDetalle GT 
		JOIN Ventas.Factura F
		ON GT.codigoFactura = F.codigoFactura COLLATE Modern_Spanish_CS_AS
		CROSS APPLY (													-- Utilizamos CROSS APPLY para seleccionar un solo producto
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

EXEC Ventas.ImportarVentas_sp @rutaVentas, @valorDolar
GO
