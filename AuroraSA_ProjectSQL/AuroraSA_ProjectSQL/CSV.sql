-----------------------------CSV

CREATE TABLE Catalogos.ProductosCSV (
    id INT,
    category VARCHAR(50),
    name NVARCHAR(100),  -- Permitir caracteres especiales
    price DECIMAL(10,2),
    reference_price DECIMAL(10,2),
    reference_unit VARCHAR(10),
    date DATETIME
);

--select * from Catalogos.ProductosCSV 
--DROP PROCEDURE CargarProductosDesdeCSV

CREATE PROCEDURE CargarProductosDesdeCSV
    @rutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear tabla temporal para cargar los datos del CSV
    CREATE TABLE #TempProductos (
        id INT,
        category VARCHAR(50),
        name NVARCHAR(100),  
        price DECIMAL(10,2),
        reference_price DECIMAL(10,2),
        reference_unit VARCHAR(10),
        date DATETIME
    );

    -- SQL dinámico para importar el archivo CSV
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
    BULK INSERT #TempProductos
    FROM ''' + @rutaArchivo + '''
    WITH (
        FORMAT = ''CSV'', 
        FIRSTROW = 2, 
        FIELDTERMINATOR = '','', 
        ROWTERMINATOR = ''0x0A'', 
        CODEPAGE = ''65001'',
        TABLOCK
    );';

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

    -- Insertar datos en la tabla final (evitando duplicados)
    INSERT INTO Catalogos.ProductosCSV (id, category, name, price, reference_price, reference_unit, date)
    SELECT * FROM #TempProductos;

    -- Limpiar la tabla temporal
    DROP TABLE #TempProductos;

    PRINT 'Importación completada correctamente.';
END;

EXEC CargarProductosDesdeCSV 'C:\Users\GVuono\OneDrive - AGT Networks\Escritorio\Nueva carpeta\catalogo.csv';

--------pasar a tabla productos

CREATE PROCEDURE InsertarProductosDesdeImportado
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Catalogos.Producto (nombreProducto, lineaProducto, marca, precioUnitario, activo)
    SELECT 
        name AS nombreProducto,
        category AS lineaProducto,   
        'Importado' AS marca,        
        price AS precioUnitario,
        1 AS activo                  
    FROM Catalogos.ProductosCSV;

    PRINT 'Productos importados correctamente.';
END;

EXEC InsertarProductosDesdeImportado;

--ALTER TABLE Catalogos.Producto
--ALTER COLUMN nombreProducto VARCHAR(100); 
--ALTER COLUMN lineaProducto VARCHAR(100); 


select * from Catalogos.Producto