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







-----------------------------CSV

CREATE OR ALTER PROCEDURE Inventario.CargarProductosCatalogoCSV_sp
    @rutaArchivo				NVARCHAR(250),
	@rutaArchivoEquivalencias	NVARCHAR(250),
	@valorDolar					DECIMAL(10,2)
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

	-- Crear tabla temporal para buscar coincidencias de linea de producto
	CREATE TABLE #TempEquivalenciaLineas (
		lineaNueva NVARCHAR(25),
		lineaVieja NVARCHAR(50)
	);
/*								  
	DECLARE @rutaArchivo NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\catalogo.csv'
	DECLARE @rutaArchivoEquivalencias NVARCHAR(250) = 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx'
	DECLARE @valorDolar INT = 1; 
*/
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

	-- SQL dinámico para importar el archivo de equivalencias de linea producto
    SET @sql = '
        INSERT INTO #TempEquivalenciaLineas (lineaNueva, lineaVieja)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivoEquivalencias + ''',
            ''SELECT * FROM [Clasificacion productos$B1:C149]'');
    ';
	EXEC sp_executesql @sql

/*	-- Creamos vista para guardar resultados de cruce de linea de productos antiguas-nuevas
	SELECT DISTINCT *
	INTO #CruceCategorias
	FROM #TempProductos1 P inner join #TempEquivalenciaLineas E on P.category = E.lineaVieja
*/

	DECLARE @maxID INT = (SELECT MAX(id) FROM #TempProductos1);
	DECLARE @minID INT = (SELECT MIN(id) FROM #TempProductos1);

	select * from #TempEquivalenciaLineas
	select * from #TempProductos1

	print @maxID
	print @minID

	WHILE @minID <= @maxID 
	BEGIN
		DECLARE @nombreProd NVARCHAR(100), @cat NVARCHAR(30), @precioUnit DECIMAL(10,2);

		-- Cargamos en variables los datos del producto actual
		SELECT @nombreProd = name, @cat = category, @precioUnit = price
        FROM #TempProductos1
        WHERE id = @minID;

		DECLARE @catNueva NVARCHAR(25) = (SELECT lineaNueva FROM #TempEquivalenciaLineas WHERE lineaVieja = @cat) 

		-- Verificamos si ya fue cargada la linea de producto del idProducto actual
		DECLARE @idLineaProd int = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = @catNueva);
		IF @idLineaProd IS NULL
		BEGIN 
			EXEC Inventario.InsertarLineaProducto_sp @catNueva
			SET @idLineaProd = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = @catNueva);
		END

		-- Se insertan datos segun el precio del dolar y el id correspondiente de la linea electrónico
		INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
		VALUES (@nombreProd,
				@idLineaProd,     
				@precioUnit*@valorDolar)              

		SET @minID = @minID + 1;
	END

	-- Limpiamos las tablas temporales
	DROP TABLE #TempEquivalenciaLineas
	--DROP TABLE #CruceCategorias
    DROP TABLE #TempProductos1;

    PRINT 'Importación completada correctamente.';
END;
GO

EXEC Inventario.CargarProductosCatalogoCSV_sp 'C:\Users\GVuono\OneDrive - AGT Networks\Escritorio\Nueva carpeta\catalogo.csv',1
EXEC Inventario.CargarProductosCatalogoCSV_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\catalogo.csv',
											  'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Informacion_complementaria.xlsx',1

SELECT * FROM Inventario.Producto



CREATE OR ALTER PROCEDURE Inventario.CargarProductosElectronicos_sp
    @rutaArchivo NVARCHAR(250),
	@valorDolar DECIMAL(10,2)
AS
BEGIN
	
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
SELECT * FROM Inventario.LineaProducto


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

	DECLARE @maxID INT = (SELECT MAX(idProducto) FROM #TempProductos);
	DECLARE @minID INT = (SELECT MIN(idProducto) FROM #TempProductos);

	--SELECT * FROM #TempProductos
	--DECLARE @valorDolar int = 1

	-- Iteramos en toda la tabla para verificar las lineas de producto
	WHILE @minID <= @maxID 
	BEGIN
		DECLARE @nombreProd NVARCHAR(100), @cat NVARCHAR(30), @precioUnit DECIMAL(10,2);

		-- Cargamos en variables los datos del producto actual
		SELECT @nombreProd = nombreProducto, @cat = categoria, @precioUnit = precioUnidad
        FROM #TempProductos
        WHERE idProducto = @minID;

		-- Verificamos si ya fue cargada la linea de producto del idProducto actual
		DECLARE @idLineaProd int = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = @cat);
		IF @idLineaProd IS NULL
		BEGIN 
			EXEC Inventario.InsertarLineaProducto_sp @cat
			SET @idLineaProd = (SELECT idLineaProd FROM Inventario.LineaProducto WHERE descripcion = @cat);
		END

		-- Se insertan datos segun el precio del dolar y el id correspondiente de la linea electrónico
		INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
		SELECT 
			@nombreProd AS nombre,
			@idLineaProd AS lineaProducto,          
			@precioUnit*@valorDolar AS precioUnitario               
		FROM #TempProductos;

		SET @minID = @minID + 1;
	END

    DROP TABLE #TempProductos;
	PRINT 'Importación completada correctamente.';
END
GO

EXEC Inventario.CargarProductosImportados_sp 'E:\Extra\Facultad\Bases de datos aplicadas\TpIntegrador\AuroraSA-DB\AuroraSA_ProjectSQL\AuroraSA_ProjectSQL\Data\Productos\Productos_importados.xlsx',1
SELECT * FROM Inventario.Producto where nombreProducto = 'Banana'
SELECT * FROM Inventario.LineaProducto