/*
Aurora SA
Pruebas de roles y nuevos procedures (Entrega 05)
Fecha: 28-02-2025
Asignatura: Bases de datos Aplicadas - Comisión: 1353
Grupo 07: Rodriguez Gonzalo (46418949) - Francisco Vladimir (46030072) - Vuono Gabriel (42134185)
*/

/*
	Ejecutar el código paso a paso siguiendo las indicaciones
	No ejecute en bloque, puede dar lugar a errores
*/

USE Com1353G07
GO
-- Ejecutar

---------------------------- ENCRIPTACIÓN ------------------------------

-- Agregamos los campos para encriptar
IF NOT EXISTS 		(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
			WHERE TABLE_NAME = 'Empresa.Empleado' AND COLUMN_NAME = 'cuil_encriptado')
	AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
			WHERE TABLE_NAME = 'Empresa.Empleado' AND COLUMN_NAME = 'domicilio_encriptado')
	AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
			WHERE TABLE_NAME = 'Empresa.Empleado' AND COLUMN_NAME = 'telefono_encriptado')
	AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
			WHERE TABLE_NAME = 'Empresa.Empleado' AND COLUMN_NAME = 'mailPersonal_encriptado')
BEGIN
    ALTER TABLE Empresa.Empleado 
	ADD	cuil_encriptado VARBINARY(256),
		domicilio_encriptado VARBINARY(256),
		telefono_encriptado VARBINARY(256),
		mailPersonal_encriptado VARBINARY(256);
END
ELSE
    PRINT 'Los campos ya existen.';
-- 1) Ejecutar hasta aca


-- Encriptamos los campos sensibles de la tabla empleado
EXEC Seguridad.EncriptarEmpleado_sp 'NoTeOlvidesElWhereEnElDeleteFrom'
-- 2) Ejecutar hasta aca

-- Vemos la nueva tabla con los datos encriptados
SELECT * FROM Empresa.Empleado
-- 3) Ejecutar hasta aca

-- Vemos la tabla, pero con los datos desencriptados
EXEC Seguridad.MostrarEmpleadoDesencriptado_sp 'NoTeOlvidesElWhereEnElDeleteFrom'
-- 4) Ejecutar hasta aca



-- Insertar y actualizar empleados con cifrado
/*
	--------------------
	InsertarEmpleado_sp
	--------------------
*/
PRINT '=== InsertarEmpleado_sp: Insertando empleado con datos cifrados ===';
EXEC Empresa.InsertarEmpleado_sp
	@clave		= 'NoTeOlvidesElWhereEnElDeleteFrom',		-- Nuevo parámetro, la clave de cifrado
	@idEmpleado	= 98,
     	@nombre		= 'Juan',
     	@apellido	= 'Perez',
     	@genero		= 'M',
     	@cargo		= 'Cajero',
     	@domicilio	= 'Avellaneda 158',
     	@telefono	= '1133558833',
     	@cuil		= '20-46415848-2',
     	@fechaAlta	= '2025-01-01',
    	@mailPersonal	= 'Rolando_LOPEZ@gmail.com',
     	@mailEmpresa	= 'Rolando.LOPEZ@superA.com',
     	@idSucursal	= 1,
     	@turno		= 'TM';

-- 5) Ejecutar hasta aca y luego observar las dos consultas.

SELECT * FROM Empresa.Empleado		--	<-- Como vemos los campos quedan encriptados
EXEC Seguridad.MostrarEmpleadoDesencriptado_sp 'NoTeOlvidesElWhereEnElDeleteFrom' --	<-- Mediante la clave podemos ver los datos encriptados

-- 6) Ejecutar hasta aca. Ocurre exactamente lo mismo para el procedure de actualizar.


-- Que suecede si intentamos ver con otra clave?
EXEC Seguridad.MostrarEmpleadoDesencriptado_sp 'EdgardoGhoBot' --		<-- No visualizamos ninguno de los campos
-- 7) Ejecutar hasta aca.

-- En caso de insertar una clave erronea:
PRINT '=== InsertarEmpleado_sp: Insertando dos empleados ===';
EXEC Empresa.InsertarEmpleado_sp
	@clave		= 'EdgardoGhoBot',	--	<-- Clave distinta
	@idEmpleado	= 100,
     	@nombre		= 'Juan',
     	@apellido	= 'Perez',
     	@genero		= 'M',
     	@cargo		= 'Cajero',
     	@domicilio	= 'Avenida SiempreViva 99',
     	@telefono	= '1133558833',
     	@cuil		= '20-46415848-2',
     	@fechaAlta	= '2025-01-01',
     	@mailPersonal	= 'Rolando_LOPEZ@gmail.com',
     	@mailEmpresa	= 'Rolando.LOPEZ@superA.com',
     	@idSucursal	= 1,
     	@turno		= 'TM';

-- 8) Ejecutar hasta aca y luego observe las dos consultas.


EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'NoTeOlvidesElWhereEnElDeleteFrom'
EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'EdgardoGhoBot'		
-- Observaremos determinados campos segun con la clave que fueron encriptados

