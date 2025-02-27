--------PARA PRODUCTOS
SELECT 
    idProducto AS '@id',
    nombreProducto AS 'Nombre',
    lineaProducto AS 'Linea',
    marca AS 'Marca',
    precioUnitario AS 'Precio',
    activo AS 'Activo'
FROM Catalogos.Producto
FOR XML PATH('Producto'), ROOT('Productos');

-----REPORTE MENSUAL------

CREATE PROCEDURE Ventas.ReporteMensual_FacturadoPorDia
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        DATENAME(WEEKDAY, fecha) AS DiaSemana,
        SUM(dv.subtotal) AS TotalFacturado
    FROM Ventas.Factura f
    JOIN Ventas.DetalleVenta dv ON f.idFactura = dv.idFactura
    WHERE YEAR(f.fecha) = @Anio AND MONTH(f.fecha) = @Mes
    GROUP BY DATENAME(WEEKDAY, fecha)
    FOR XML PATH('Dia'), ROOT('ReporteMensual')
END;

EXEC Ventas.ReporteMensual_FacturadoPorDia @Mes = 1, @Anio = 2025;

-----------TRIMESTRAL---------

CREATE PROCEDURE Ventas.Reporte_TotalFacturadoPorTurno
    @Trimestre INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MONTH(f.fecha) AS 'Mes',
        CASE 
            WHEN f.hora BETWEEN '06:00:00' AND '13:59:59' THEN 'Mañana'
            WHEN f.hora BETWEEN '14:00:00' AND '21:59:59' THEN 'Tarde'
            ELSE 'Noche'
        END AS 'TurnoTrabajo',
        SUM(dv.cantidad * dv.precioUnitario) AS 'TotalFacturado'
    FROM Ventas.Factura f
    JOIN Ventas.DetalleVenta dv ON f.idFactura = dv.idFactura
    WHERE DATEPART(QUARTER, f.fecha) = @Trimestre AND YEAR(f.fecha) = @Anio
    GROUP BY MONTH(f.fecha), 
             CASE 
                WHEN f.hora BETWEEN '06:00:00' AND '13:59:59' THEN 'Mañana'
                WHEN f.hora BETWEEN '14:00:00' AND '21:59:59' THEN 'Tarde'
                ELSE 'Noche'
             END
    ORDER BY Mes, TurnoTrabajo
    FOR XML PATH('Turno'), ROOT('TotalFacturadoPorTurno');
END;


EXEC Ventas.Reporte_TotalFacturadoPorTurno @Trimestre = 1, @Anio = 2025;

------------------RANGO FECHA--------

CREATE PROCEDURE Ventas.Reporte_ProductosVendidosPorRango
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.nombreProducto AS 'Producto',
        SUM(dv.cantidad) AS 'CantidadVendida'
    FROM Ventas.DetalleVenta dv
    JOIN Catalogos.Producto p ON dv.idProducto = p.idProducto
    JOIN Ventas.Factura f ON dv.idFactura = f.idFactura
    WHERE f.fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY p.nombreProducto
    ORDER BY CantidadVendida DESC
    FOR XML PATH('Producto'), ROOT('ProductosVendidos');
END;

EXEC Ventas.Reporte_ProductosVendidosPorRango @FechaInicio = '2025-01-01', @FechaFin = '2025-01-31';

-----------------SUCURSAL---------

CREATE PROCEDURE Ventas.Reporte_ProductosVendidosPorSucursal
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.nombreSucursal AS 'Sucursal',
        p.nombreProducto AS 'Producto',
        SUM(dv.cantidad) AS 'CantidadVendida'
    FROM Ventas.DetalleVenta dv
    JOIN Catalogos.Producto p ON dv.idProducto = p.idProducto
    JOIN Ventas.Factura f ON dv.idFactura = f.idFactura
    JOIN Personas.Sucursal s ON f.idSucursal = s.idSucursal
    WHERE f.fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY s.nombreSucursal, p.nombreProducto
    ORDER BY s.nombreSucursal, CantidadVendida DESC
    FOR XML PATH('Sucursal'), ROOT('ProductosVendidosPorSucursal');
END;

EXEC Ventas.Reporte_ProductosVendidosPorSucursal @FechaInicio = '2025-01-01', @FechaFin = '2025-01-31';

------------TOP5 MAS VENDIDOS

CREATE PROCEDURE Ventas.Reporte_Top5ProductosPorSemana
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH ProductosVendidos AS (
        SELECT 
            DATEPART(WEEK, f.fecha) AS 'Semana',
            p.nombreProducto AS 'Producto',
            SUM(dv.cantidad) AS 'CantidadVendida'
        FROM Ventas.DetalleVenta dv
        JOIN Catalogos.Producto p ON dv.idProducto = p.idProducto
        JOIN Ventas.Factura f ON dv.idFactura = f.idFactura
        WHERE MONTH(f.fecha) = @Mes AND YEAR(f.fecha) = @Anio
        GROUP BY DATEPART(WEEK, f.fecha), p.nombreProducto
    )
    SELECT 
        Semana,
        Producto,
        CantidadVendida
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY Semana ORDER BY CantidadVendida DESC) AS Ranking
        FROM ProductosVendidos
    ) AS Ranked
    WHERE Ranking <= 5
    ORDER BY Semana, Ranking
    FOR XML PATH('Producto'), ROOT('Top5ProductosPorSemana');
END;

EXEC Ventas.Reporte_Top5ProductosPorSemana @Mes = 1, @Anio = 2025;

--------------TOP5 MENOS VENDIDOS

CREATE PROCEDURE Ventas.Reporte_Top5ProductosMenosVendidos
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 5
        p.nombreProducto AS 'Producto',
        SUM(dv.cantidad) AS 'CantidadVendida'
    FROM Ventas.DetalleVenta dv
    JOIN Catalogos.Producto p ON dv.idProducto = p.idProducto
    JOIN Ventas.Factura f ON dv.idFactura = f.idFactura
    WHERE MONTH(f.fecha) = @Mes AND YEAR(f.fecha) = @Anio
    GROUP BY p.nombreProducto
    ORDER BY CantidadVendida ASC
    FOR XML PATH('Producto'), ROOT('Top5MenosVendidos');
END;

EXEC Ventas.Reporte_Top5ProductosMenosVendidos @Mes = 1, @Anio = 2025;

----------------VENTAS X FECHA Y SUCURSAL

CREATE PROCEDURE Ventas.Reporte_TotalAcumuladoVentas
    @Fecha DATE,
    @idSucursal INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.nombreSucursal AS 'Sucursal',
        SUM(dv.cantidad * dv.precioUnitario) AS 'TotalVentas'
    FROM Ventas.Factura f
    JOIN Ventas.DetalleVenta dv ON f.idFactura = dv.idFactura
    JOIN Personas.Sucursal s ON f.idSucursal = s.idSucursal
    WHERE f.fecha = @Fecha AND f.idSucursal = @idSucursal
    GROUP BY s.nombreSucursal
    FOR XML PATH('TotalVentas'), ROOT('AcumuladoVentas');
END;

EXEC Ventas.Reporte_TotalAcumuladoVentas @Fecha = '2025-01-01', @idSucursal = 9;

--------------MAYOR MONTO FACTURADO

CREATE PROCEDURE Ventas.Reporte_VendedorMayorFacturacion
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH FacturacionVendedor AS (
        SELECT 
            s.nombreSucursal AS 'Sucursal',
            e.nombre + ' ' + e.apellido AS 'Vendedor',
            SUM(dv.cantidad * dv.precioUnitario) AS 'TotalFacturado'
        FROM Ventas.Factura f
        JOIN Ventas.DetalleVenta dv ON f.idFactura = dv.idFactura
        JOIN Personas.Empleado e ON f.idEmpleado = e.idEmpleado
        JOIN Personas.Sucursal s ON f.idSucursal = s.idSucursal
        WHERE MONTH(f.fecha) = @Mes AND YEAR(f.fecha) = @Anio
        GROUP BY s.nombreSucursal, e.nombre, e.apellido
    )
    SELECT 
        Sucursal,
        Vendedor,
        TotalFacturado
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY Sucursal ORDER BY TotalFacturado DESC) AS Ranking
        FROM FacturacionVendedor
    ) AS Ranked
    WHERE Ranking = 1
    FOR XML PATH('Vendedor'), ROOT('VendedorMayorFacturacion');
END;

EXEC Ventas.Reporte_VendedorMayorFacturacion @Mes = 1, @Anio = 2025;

