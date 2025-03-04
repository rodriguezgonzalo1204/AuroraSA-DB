/*
Aurora SA
Creacion de Procedures para importación (Entrega 04)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Francisco Vladimir (46030072) - Vuono Gabriel (42134185)
*/

---------------------------------------------------------------------------------------------------------------------------

/*	
	Modo de ejecución
	El script esta pensado para poder ejecutarse de un solo bloque con F5. Se crearan los 
	procedures de imporatción y se cambiarán las configuraciones para permitirlo
*/


USE Com1353G07
GO

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
        category NVARCHAR(50) COLLATE Modern_Spanish_CS_AS,
        name NVARCHAR(110) COLLATE Modern_Spanish_CI_AI,  
        price DECIMAL(10,2),
        reference_price DECIMAL(10,2),
        reference_unit VARCHAR(10) COLLATE Modern_Spanish_CS_AS,
        date DATETIME 
    );

	CREATE NONCLUSTERED INDEX ix_tempNombreInclude ON #TempProductos1(name) INCLUDE (price, date, category);

    -- Crear tabla temporal para buscar coincidencias de línea de producto
    CREATE TABLE #TempEquivalenciaLineas (
		lineaVieja NVARCHAR(50) COLLATE Modern_Spanish_CS_AS PRIMARY KEY,		-- Se encuentra ordenado en el archivo origen por lo que la insercion es eficiente
        lineaNueva NVARCHAR(25) COLLATE Modern_Spanish_CS_AS
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
            ''SELECT * FROM [Clasificacion productos$B1:C]'');
    ';
    EXEC sp_executesql @sql;

    -- Insertar las nuevas líneas de producto que no existen
    INSERT INTO Inventario.LineaProducto (descripcion)
    SELECT DISTINCT E.lineaNueva
    FROM #TempEquivalenciaLineas E
		LEFT JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion
    WHERE LP.idLineaProd IS NULL;

	-- Se utiliza row_number para filtrar productos con nombre duplicado, se va a dejar solo el mas reciente
	WITH ProductosFiltrados AS (
        SELECT 
			name, 
            category,
            price,
            date,
            ROW_NUMBER() OVER (PARTITION BY name ORDER BY date DESC) AS rn
        FROM #TempProductos1 
    )
    -- Insertar productos con el precio más reciente
    INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
    SELECT 
        PF.name, 
        LP.idLineaProd, 
        PF.price * @valorDolar
    FROM ProductosFiltrados PF
		JOIN #TempEquivalenciaLineas E ON PF.category = E.lineaVieja 
		JOIN Inventario.LineaProducto LP ON E.lineaNueva = LP.descripcion
    WHERE PF.rn = 1  -- Solo insertar la versión más reciente de cada producto
		AND NOT EXISTS (SELECT 1 FROM Inventario.Producto P WHERE P.nombreProducto = PF.name);	-- Verifica que el producto no exista

    -- Limpiar tablas temporales
    DROP TABLE #TempEquivalenciaLineas;
    DROP TABLE #TempProductos1;

END;
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
        nombre NVARCHAR(110) COLLATE Modern_Spanish_CI_AI,
        precio DECIMAL(10,2)
    );

	CREATE NONCLUSTERED INDEX ix_tempNombre ON #TempProductos(nombre) INCLUDE (precio)

    -- Insertar datos desde el archivo XLSX
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
        INSERT INTO #TempProductos (Nombre, Precio)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''',
            ''SELECT * FROM [Sheet1$B1:C]'');
    ';
	EXEC sp_executesql @sql;

	WITH ElecFiltrados AS (
		SELECT *,
			ROW_NUMBER() OVER(PARTITION BY nombre ORDER BY precio desc) rn
		FROM #TempProductos
	)

	-- Se insertan datos segun el precio del dolar y el id correspondiente de la linea electrónico
	INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
    SELECT 
        nombre AS nombre,
        @idLineaProd AS lineaProducto,          
        precio*@valorDolar AS precioUnitario               
    FROM ElecFiltrados 
	WHERE rn = 1
		AND NOT EXISTS (SELECT 1 FROM Inventario.Producto P WHERE P.nombreProducto = nombre);


    DROP TABLE #TempProductos;
END
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
        NombreProducto NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,
        Proveedor NVARCHAR(100) COLLATE Modern_Spanish_CS_AS,
		Categoria NVARCHAR(30) COLLATE Modern_Spanish_CS_AS,
		CantidadPorUnidad VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
        precioUnidad DECIMAL(10,2)
    );

	CREATE NONCLUSTERED INDEX ix_tempNombre ON #TempProductos(NombreProducto, precioUnidad) INCLUDE (Categoria)

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
		JOIN Inventario.LineaProducto LP ON TP.Categoria = LP.descripcion
    WHERE LP.idLineaProd IS NULL;

	WITH ImpFiltrados AS
	(
		SELECT *,
			ROW_NUMBER() OVER(PARTITION BY NombreProducto ORDER BY precioUnidad desc) rn
		FROM #TempProductos
	)

    -- Insertar productos con join para optimizar
    INSERT INTO Inventario.Producto (nombreProducto, lineaProducto, precioUnitario)
    SELECT TP.NombreProducto, LP.idLineaProd, TP.precioUnidad * @valorDolar
    FROM ImpFiltrados TP
		JOIN Inventario.LineaProducto LP ON TP.Categoria = LP.descripcion
	WHERE TP.rn = 1
		AND NOT EXISTS (SELECT 1 FROM Inventario.Producto P WHERE P.nombreProducto = TP.NombreProducto);

    DROP TABLE #TempProductos;
END
GO

-----------------------------------------------------------------------------------------------
-- Importacion de sucursales
CREATE OR ALTER PROCEDURE Empresa.ImportarSucursales_sp
    @rutaArchivo NVARCHAR(250) 
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	SET @sql = '
		INSERT INTO Empresa.Sucursal (ciudad, direccion, horario, telefono)
		SELECT *
		FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
			''Excel 12.0 Xml;HDR=YES;IMEX=1;Database=' + @rutaArchivo + ''',
			''SELECT * FROM [sucursal$C2:F]'');
	';
	EXEC sp_executesql @sql;
END;
GO

-----------------------------------------------------------------------------------------------
-- Funcion para cuil random
CREATE OR ALTER FUNCTION Utilidades.Generarcuil(@dni VARCHAR(20)) 
RETURNS CHAR(13)
AS
BEGIN
    DECLARE @cuil CHAR(13),
			@codigoVerificacion INT,
			@prefijo INT;
    
    -- Generamos un valor aleatorio que solo puede ser 20 o 27
    IF (ABS(CHECKSUM(CURRENT_TIMESTAMP)) % 2) = 0
        SET @prefijo = 20;
    ELSE
        SET @prefijo = 27;
    
    -- Último dígito
    SET @codigoVerificacion = ABS(CHECKSUM(CURRENT_TIMESTAMP)) % 10;

    -- Formatear
    SET @cuil = CAST(@prefijo AS VARCHAR(2)) + '-' + @dni + '-' + CAST(@codigoVerificacion AS VARCHAR(1));

    RETURN @cuil;
END;
GO

-----------------------------------------------------------------------------------------------
-- Importacion de empleados
CREATE OR ALTER PROCEDURE Empresa.ImportarEmpleados_sp
    @rutaArchivo NVARCHAR(250) 
AS
BEGIN
    SET NOCOUNT ON -- apagar

    CREATE TABLE #TempEmpleados (
		idEmpleado INT,
		nombre VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
		apellido VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
		dni	VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
		domicilio NVARCHAR(100) COLLATE Modern_Spanish_CS_AS,
		mailPersonal VARCHAR(55) COLLATE Modern_Spanish_CS_AS,
		mailEmpresa VARCHAR(55) COLLATE Modern_Spanish_CS_AS,
		cuil CHAR(13) COLLATE Modern_Spanish_CS_AS,
		cargo VARCHAR(25) COLLATE Modern_Spanish_CS_AS,
		ciudadSuc VARCHAR(30) COLLATE Modern_Spanish_CS_AS,
		turno	VARCHAR(20) COLLATE Modern_Spanish_CS_AS
    );

	CREATE CLUSTERED INDEX ix_tempIdEmpleado ON #TempEmpleados(idEmpleado);

    DECLARE @cadenaSql NVARCHAR(MAX)
    SET @cadenaSql = '
        INSERT INTO #TempEmpleados (idEmpleado, nombre, apellido, dni, domicilio, mailPersonal, mailEmpresa, cuil, cargo, ciudadSuc, turno)
        SELECT *
        FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0 Xml;HDR=YES;Database=' + @rutaArchivo + ''',
            ''SELECT * FROM [Empleados$A2:K]'');
    ';
    EXEC sp_executesql @cadenaSql

	-- Variables para generar fecha random entre los limites establecidos
	DECLARE @FechaInicio AS date,
			@FechaFin AS date,
			@DiasIntervalo AS int;

	SELECT	@FechaInicio   = '20220101',
			@FechaFin     = '20250227',
			@DiasIntervalo = (1+DATEDIFF(DAY, @FechaInicio, @FechaFin));
	
	-- Con row_number identificamos si existen dnis duplicados dentro del arcivo de importacion
	WITH EmpsCTE AS (
         SELECT *,
			ROW_NUMBER() OVER (PARTITION BY dni ORDER BY idEmpleado) rn
         FROM #TempEmpleados
    ) 
	
    -- Insetamos dentro de la tabla empleados
    INSERT INTO Empresa.Empleado (idEmpleado, nombre, apellido, genero, cargo, domicilio, telefono, cuil, fechaAlta, mailPersonal, mailEmpresa, idSucursal, turno)
	SELECT
		TE.idEmpleado,
		TE.nombre,
		TE.apellido,
		CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'F' ELSE 'M' END AS genero,	-- Genero aleatorio
		TE.cargo,
		TE.domicilio,
		'11' + RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR(8)), 8) AS telefono,	-- Numero aleatorio de 10 digitos
		Utilidades.Generarcuil(TE.dni),
		DATEADD(DAY, RAND(CHECKSUM(NEWID())) * @DiasIntervalo, @FechaInicio),
		TE.mailPersonal,
		TE.mailEmpresa,
		S.idSucursal,
		TE.turno
	FROM EmpsCTE TE
		JOIN Empresa.Sucursal S ON TE.ciudadSuc = S.ciudad
	WHERE TE.rn = 1		-- Insertamos solo una aparicion por DNI
		AND NOT EXISTS (
			SELECT 1 
			FROM Empresa.Empleado E 
			WHERE SUBSTRING(E.cuil, 4, 8) = TE.dni -- Verificamos que el dni no se encuentre en la tabla
		)	
		AND NOT EXISTS (
			SELECT 1 
			FROM Empresa.Empleado E
			WHERE E.idEmpleado = TE.idEmpleado						   -- Verificamos que no exista otro empleado con el mismo legajo
	 );
 
	DROP TABLE #TempEmpleados

END;
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

    PRINT CAST(@cantidad AS VARCHAR) + ' clientes aleatorios cargados correctamente.';
END;
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
        codigoFactura CHAR(11) COLLATE Modern_Spanish_CS_AS,
		tipoFactura CHAR(1) COLLATE Modern_Spanish_CS_AS,
		ciudad VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
		tipoCliente VARCHAR(10) COLLATE Modern_Spanish_CS_AS,
		genero VARCHAR(10) COLLATE Modern_Spanish_CS_AS,
        nombreProducto NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,
		precioUnitario DECIMAL(10,2),
		cantidad INT,
		fecha VARCHAR(10) COLLATE Modern_Spanish_CS_AS,
		hora VARCHAR(15) COLLATE Modern_Spanish_CS_AS,
		medioPago VARCHAR(20) COLLATE Modern_Spanish_CS_AS,
		idEmpleado INT,
		identificadorPago VARCHAR(35) COLLATE Modern_Spanish_CS_AS
    );

	CREATE CLUSTERED INDEX ix_tempCodFact ON #TempVentas(codigoFactura)

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
        codigoFactura CHAR(11) COLLATE Modern_Spanish_CS_AS PRIMARY KEY,
        total DECIMAL(10, 2) 
    );

    -- Calcular el total por factura agrupando por codigoFactura
    INSERT INTO #TotalesPorFactura (codigoFactura, total)
    SELECT codigoFactura, SUM(precioUnitario * cantidad * @valorDolar) AS total
    FROM #TempVentas
    GROUP BY codigoFactura;

    INSERT INTO Ventas.Factura (codigoFactura, medioPago, tipoFactura, fecha, hora, identificadorPago, total, idCliente, idEmpleado, idSucursal)
    SELECT 
        V.codigoFactura,
        MAX(V.medioPago) AS medioPago,				-- Utilizamos MAX porque se supone que para una misma factura, el medio de pago, tipo, cliente, empleado, etc. es exactamente el mismo
        MAX(V.tipoFactura) AS tipoFactura,			
        MAX(CONVERT(DATE, V.fecha, 101)) AS fecha,  -- 101 corresponde al formato MM/DD/AAAA
        MAX(V.hora) AS hora,						
        MAX(identificadorPago) AS identificadorPago,
        TF.total,
        MAX(C.idCliente) AS idCliente,         
        MAX(V.idEmpleado) AS idEmpleado,       
        MAX(S.idSucursal) AS idSucursal        
    FROM #TempVentas V
		JOIN #TotalesPorFactura TF ON V.codigoFactura = TF.codigoFactura
		CROSS APPLY (								-- Utilizamos CROSS APLY para asignar un cliente aleatorio que cumpla con tipo y genero
			SELECT TOP 1 idCliente 
			FROM Ventas.Cliente
			WHERE genero = LEFT(V.genero, 1) 		-- Con LEFT nos quedamos solo con el primer digito del genero (Female -> F)
				AND tipoCliente = V.tipoCliente 
			ORDER BY NEWID(), V.codigoFactura		-- Se detalla en documentacion el motivo de agregar un campo adicional al ordenamiento al usar NEWID
		) C	
		JOIN Empresa.Sucursal S ON V.ciudad = S.ciudad
    GROUP BY V.codigoFactura, TF.total;
		

	CREATE TABLE #GruposDetalle (
		codigoFactura CHAR(11) COLLATE Modern_Spanish_CS_AS,
		idDetalle INT,
		nombreProd NVARCHAR(100) COLLATE Modern_Spanish_CI_AI,
		precioUnitario DECIMAL(10,2),
		cantidad INT,
		subtotal DECIMAL(10,2)
		CONSTRAINT tempPK_GruposVenta PRIMARY KEY (codigoFactura,idDetalle) 
	);

	-- Utilizamos row_number para indicar cuantos detalles corresponden a una misma factura (Para el caso del archivo "Ventas" es 1 item por factura por lo que no se ve reflejado el cambio)
	INSERT INTO #GruposDetalle(codigoFactura, idDetalle, nombreProd, precioUnitario, cantidad, subtotal)
	SELECT  codigoFactura,
			ROW_NUMBER() OVER(PARTITION BY codigoFactura ORDER BY codigoFactura) as idDetalle,
			nombreProducto, precioUnitario, cantidad, cantidad*precioUnitario*@valorDolar as subtotal
	FROM #TempVentas

	INSERT INTO Ventas.DetalleVenta (idFactura, idDetalle, idProducto, precioUnitario, cantidad, subtotal)
	SELECT F.idFactura, GT.idDetalle, P.idProducto, GT.precioUnitario, GT.cantidad, GT.subtotal
	FROM #GruposDetalle GT 
		JOIN Ventas.Factura F ON GT.codigoFactura = F.codigoFactura
		JOIN Inventario.Producto P ON GT.nombreProd = P.nombreProducto;

	DROP TABLE #TempVentas;
	DROP TABLE #TotalesPorFactura
	DROP TABLE #GruposDetalle

END
GO
