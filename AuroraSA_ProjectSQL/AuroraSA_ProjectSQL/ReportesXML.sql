/*
Aurora SA
Generacion de reportes. (Entrega 04)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Vladimir Francisco (46030072) - Vuono Gabriel (42134185)
*/

Use Com1353G07
GO

/*	
	Ejecutar con F5 para creación de procedures.
	Luego seleccionar y ejecutar los EXEC de prueba para ver resultados de cada reporte
*/

------------------------------------------------------------------------
-- XML de catálogo de productos --
CREATE OR ALTER PROCEDURE Utilidades.CatalogoXML_sp
AS
BEGIN
	SELECT 
		idProducto AS '@id',
		nombreProducto AS 'Nombre',
		lineaProducto AS 'Linea',
		precioUnitario AS 'Precio',
		activo AS 'Activo'
	FROM Inventario.Producto
	FOR XML PATH('Producto'), ROOT('Productos');
END;
GO

-- Ejecucion de prueba
-- EXEC Utilidades.CatalogoXML_sp

------------------------------------------------------------------------
------------------------ REPORTE MENSUAL ------------------------
-- Recibe mes y año, muestra total facturado por dias de la semana

CREATE OR ALTER PROCEDURE Reportes.ReporteMensual_FacturadoPorDia_sp
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        DATENAME(WEEKDAY, fecha) AS DiaSemana,
        SUM(f.total) AS TotalFacturado
    FROM Ventas.Factura f
    WHERE YEAR(f.fecha) = @Anio AND MONTH(f.fecha) = @Mes
    GROUP BY DATENAME(WEEKDAY, fecha)
    ORDER BY MIN(f.fecha) 
    FOR XML PATH('Dia'), ROOT('ReporteMensual');
END;
GO

-- Ejecucion de prueba
-- EXEC Reportes.ReporteMensual_FacturadoPorDia_sp @Mes = 1, @Anio = 2019;

------------------------------------------------------------------------
------------------------ REPORTE TRIMESTRAL ------------------------
-- Recibe trimestre y año, muestra el total facturado por turnos de trabajo por mes
CREATE OR ALTER PROCEDURE Reportes.Reporte_TotalFacturadoPorTurno_sp
    @Trimestre INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MONTH(f.fecha) AS Mes,
        e.turno AS TurnoTrabajo,
        SUM(dv.cantidad * dv.precioUnitario) AS TotalFacturado
    FROM Ventas.Factura f
    JOIN Ventas.DetalleVenta dv ON f.idFactura = dv.idFactura
    JOIN Empresa.Empleado e ON f.idEmpleado = e.idEmpleado
    WHERE 
        DATEPART(QUARTER, f.fecha) = @Trimestre 
        AND YEAR(f.fecha) = @Anio
    GROUP BY 
        MONTH(f.fecha), 
        e.turno
    ORDER BY Mes, TurnoTrabajo
    FOR XML PATH('Turno'), ROOT('TotalFacturadoPorTurno');
END;
GO

-- Ejecucion de prueba
-- EXEC Reportes.Reporte_TotalFacturadoPorTurno_sp @Trimestre = 1, @Anio = 2019;

------------------------------------------------------------------------
--------------- REPORTE POR RANGO DE FECHAS (PRODUCTOS) ---------------
-- Recibe rango de fechas,  muestra  la cantidad de productos vendidos, ordenado de mayor a menor.

CREATE OR ALTER PROCEDURE Reportes.Reporte_ProductosVendidosPorRango_sp
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.nombreProducto AS 'Producto',
        SUM(dv.cantidad) AS 'CantidadVendida'
    FROM Ventas.DetalleVenta dv
    JOIN Inventario.Producto p ON dv.idProducto = p.idProducto
    JOIN Ventas.Factura f ON dv.idFactura = f.idFactura
    WHERE f.fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY p.nombreProducto
    ORDER BY CantidadVendida DESC
    FOR XML PATH('Producto'), ROOT('ProductosVendidos');
END;
GO

-- Ejecucion de prueba
-- EXEC Reportes.Reporte_ProductosVendidosPorRango_sp @FechaInicio = '2019-01-01', @FechaFin = '2019-05-31';

------------------------------------------------------------------------
--------------- REPORTE POR RANGO DE FECHAS (SUCURSALES)---------------
-- Recibe rango de fechas, muestra la cantidad de productos vendidos por sucursal, ordenado de mayor a menor

CREATE OR ALTER PROCEDURE Reportes.Reporte_ProductosVendidosPorSucursal_sp
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.ciudad AS 'Sucursal',
        p.nombreProducto AS 'Producto',
        SUM(dv.cantidad) AS 'CantidadVendida'
    FROM Ventas.DetalleVenta dv
    JOIN Inventario.Producto p ON dv.idProducto = p.idProducto
    JOIN Ventas.Factura f ON dv.idFactura = f.idFactura
    JOIN Empresa.Sucursal s ON f.idSucursal = s.idSucursal
    WHERE f.fecha BETWEEN @FechaInicio AND @FechaFin
    GROUP BY s.ciudad, p.nombreProducto
    ORDER BY s.ciudad, CantidadVendida DESC
    FOR XML PATH('Sucursal'), ROOT('ProductosVendidosPorSucursal');
END;
GO
-- Ejecucion de prueba
-- EXEC Reportes.Reporte_ProductosVendidosPorSucursal_sp @FechaInicio = '2019-01-01', @FechaFin = '2019-05-31';

------------------------------------------------------------------------
---------------------------- TOP 5 VENDIDOS ----------------------------
-- Recibe mes y año, muestra los 5 productos mas vendidos por semana

CREATE OR ALTER PROCEDURE Reportes.Reporte_Top5ProductosPorSemana_sp
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
        JOIN Inventario.Producto p ON dv.idProducto = p.idProducto
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
GO

-- Ejecucion de prueba
-- EXEC Reportes.Reporte_Top5ProductosPorSemana_sp @Mes = 3, @Anio = 2019;

------------------------------------------------------------------------
------------------------- TOP 5 MENOS VENDIDOS -------------------------
-- Recibe mes y año, muestra los 5 productos menos vendidos

CREATE OR ALTER PROCEDURE Reportes.Reporte_Top5ProductosMenosVendidos_sp
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 5
        p.nombreProducto AS 'Producto',
        SUM(dv.cantidad) AS 'CantidadVendida'
    FROM Ventas.DetalleVenta dv
    JOIN Inventario.Producto p ON dv.idProducto = p.idProducto
    JOIN Ventas.Factura f ON dv.idFactura = f.idFactura
    WHERE MONTH(f.fecha) = @Mes AND YEAR(f.fecha) = @Anio
    GROUP BY p.nombreProducto
    ORDER BY CantidadVendida ASC
    FOR XML PATH('Producto'), ROOT('Top5MenosVendidos');
END;
GO

-- Ejecucion de prueba
-- EXEC Reportes.Reporte_Top5ProductosMenosVendidos_sp @Mes = 2, @Anio = 2019;

------------------------------------------------------------------------
------------------------- TOTAL ACUMULADO -------------------------
-- Recibe fecha y sucursal, muestra total acumulado y detalle

CREATE OR ALTER PROCEDURE Reportes.Reporte_TotalAcumuladoVentas_sp
    @Fecha DATE,
    @idSucursal INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.ciudad AS 'Sucursal',
        f.idFactura AS 'Factura',
        p.nombreProducto AS 'Producto',
        dv.cantidad AS 'Cantidad',
        dv.precioUnitario AS 'PrecioUnitario',
        dv.cantidad * dv.precioUnitario AS 'Subtotal'
    FROM Ventas.Factura f
    JOIN Ventas.DetalleVenta dv ON f.idFactura = dv.idFactura
    JOIN Inventario.Producto p ON dv.idProducto = p.idProducto
    JOIN Empresa.Sucursal s ON f.idSucursal = s.idSucursal
    WHERE f.fecha = @Fecha AND f.idSucursal = @idSucursal
    ORDER BY f.idFactura, p.nombreProducto
    FOR XML PATH('Venta'), ROOT('AcumuladoVentas');
END;
GO

-- Ejecucion de prueba
-- EXEC Reportes.Reporte_TotalAcumuladoVentas_sp @Fecha = '2019-02-03', @idSucursal = 1;

------------------------------------------------------------------------
------------------------- MENSUAL VENDEDOR  -------------------------
-- Recibe mes y año, muestra el vendedor de mayor monto facturado por sucursal.


CREATE OR ALTER PROCEDURE Reportes.Reporte_VendedorMayorFacturacion_sp
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH FacturacionVendedor AS (
        SELECT 
            s.ciudad AS 'Sucursal',
            e.nombre + ' ' + e.apellido AS 'Vendedor',
            SUM(dv.cantidad * dv.precioUnitario) AS 'TotalFacturado'
        FROM Ventas.Factura f
        JOIN Ventas.DetalleVenta dv ON f.idFactura = dv.idFactura
        JOIN Empresa.Empleado e ON f.idEmpleado = e.idEmpleado
        JOIN Empresa.Sucursal s ON f.idSucursal = s.idSucursal
        WHERE MONTH(f.fecha) = @Mes AND YEAR(f.fecha) = @Anio
        GROUP BY s.ciudad, e.nombre, e.apellido
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
GO

-- Ejecucion de prueba
-- EXEC Reportes.Reporte_VendedorMayorFacturacion_sp @Mes = 1, @Anio = 2019;

