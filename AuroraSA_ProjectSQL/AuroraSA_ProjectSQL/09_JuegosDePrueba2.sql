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


---------------------------- ROLES ----------------------------

-- Ejecutamos como el usuario 'GonzaloRodriguez', que posee rol "Cajero",
-- por lo que no debe tener permisos para realizar notas de crédito
EXECUTE AS USER = 'GonzaloRodriguez';
EXEC Seguridad.GenerarNotaCredito_sp 2,60,6.25,'Palangana' ;
REVERT;

-- Ejecutar hasta acá <--- ; Resultado esperado -> El usuario no tiene permisos

-- Ejecutamos como el usuario 'VladimirFrancisco', que posee rol "Supervisor",
-- y por lo tanto debe poder realizar notas de crédito
EXECUTE AS USER = 'VladimirFrancisco';
EXEC Seguridad.GenerarNotaCredito_sp 2,60,6.25,'Palangana' ;
REVERT;

SELECT * FROM Ventas.NotaCredito
-- Ejecutar hasta acá <--- ; Resultado esperado -> Nota de Crédito insertada

-----------------------------------------------------------------------------------------------------

---------------------------- ENCRIPTACIÓN ----------------------------

-- Encriptamos los campos sensibles de la tabla empleado
EXEC Seguridad.EncriptarEmpleado_sp 'NoTeOlvidesElWhereEnElDeleteFrom'

-- Vemos la nueva tabla con los datos encriptados
SELECT * FROM Empresa.Empleado

-- Vemos la tabla, pero con los datos desencriptados
EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'NoTeOlvidesElWhereEnElDeleteFrom'




-- Insertar y actualizar empleados con cifrado
/*
	--------------------
	InsertarEmpleado_sp
	--------------------
*/
PRINT '=== InsertarEmpleado_sp: Insertando empleado con datos cifrados ===';
EXEC Empresa.InsertarEmpleado_sp
	 @clave			= 'NoTeOlvidesElWhereEnElDeleteFrom',		-- Nuevo parámetro, la clave de cifrado
	 @idEmpleado	= 98,
     @nombre		= 'Juan',
     @apellido		= 'Perez',
     @genero		= 'M',
     @cargo			= 'Cajero',
     @domicilio		= 'Avellaneda 158',
     @telefono		= '1133558833',
     @cuil			= '20-46415848-2',
     @fechaAlta		= '2025-01-01',
     @mailPersonal	= 'Rolando_LOPEZ@gmail.com',
     @mailEmpresa	= 'Rolando.LOPEZ@superA.com',
     @idSucursal	= 1,
     @turno			= 'TM';

-- Ejecute hasta aca y luego observe las dos consultas.

SELECT * FROM Empresa.Empleado		--	<-- Como vemos los campos quedan encriptados
EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'NoTeOlvidesElWhereEnElDeleteFrom' --	<-- Mediante la clave podemos ver los datos encriptados

-- Ocurre exactamente lo mismo para el procedure de actualizar.


-- Que suecede si intentamos ver con otra clave?
EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'EdgardoGhoBot' --		<-- No visualizamos ninguno de los campos


-- En caso de insertar una clave erronea:
PRINT '=== InsertarEmpleado_sp: Insertando dos empleados ===';
EXEC Empresa.InsertarEmpleado_sp
	 @clave			= 'EdgardoGhoBot',	--	<-- Clave distinta
	 @idEmpleado	= 100,
     @nombre		= 'Juan',
     @apellido		= 'Perez',
     @genero		= 'M',
     @cargo		= 'Cajero',
     @domicilio		= 'Avenida SiempreViva 99',
     @telefono		= '1133558833',
     @cuil		= '20-46415848-2',
     @fechaAlta		= '2025-01-01',
     @mailPersonal	= 'Rolando_LOPEZ@gmail.com',
     @mailEmpresa	= 'Rolando.LOPEZ@superA.com',
     @idSucursal	= 1,
     @turno		= 'TM';

-- Ejecute hasta aca y luego observe las dos consultas.
EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'NoTeOlvidesElWhereEnElDeleteFrom'
EXEC Seguridad.MostrarEmpleadoEncriptado_sp 'EdgardoGhoBot'		

-- Observaremos determinados campos segun con la clave que fueron encriptados

