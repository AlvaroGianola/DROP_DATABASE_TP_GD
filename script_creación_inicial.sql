USE GD2C2025;

GO

-- Crear esquema
CREATE SCHEMA DROP_DATABASE;
GO



------------------------------------------------------------
-- TABLAS BASE
------------------------------------------------------------

CREATE TABLE DROP_DATABASE.Categoria (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255) NOT NULL
);

CREATE TABLE DROP_DATABASE.Provincia (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255) NOT NULL
);

CREATE TABLE DROP_DATABASE.Localidad (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255) NOT NULL,
    provinciaId INT NOT NULL 
        REFERENCES DROP_DATABASE.Provincia(id)
);

CREATE TABLE DROP_DATABASE.Institucion (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255) NOT NULL,
    razonSocial NVARCHAR(255),
    cuit NVARCHAR(255)
);

CREATE TABLE DROP_DATABASE.Sede (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255) NOT NULL,
    telefono NVARCHAR(255),
    direccion NVARCHAR(255),
    localidadId INT NOT NULL REFERENCES DROP_DATABASE.Localidad(id),
    mail NVARCHAR(255),
    institucionId INT NOT NULL REFERENCES DROP_DATABASE.Institucion(id)
);

CREATE TABLE DROP_DATABASE.Profesor (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    localidadId INT NOT NULL REFERENCES DROP_DATABASE.Localidad(id),
    apellido NVARCHAR(255),
    nombre NVARCHAR(255),
    dni NVARCHAR(255),
    fechaNacimiento DATETIME2(6),
    direccion NVARCHAR(255),
    telefono NVARCHAR(255),
    mail NVARCHAR(255)
);

CREATE TABLE DROP_DATABASE.Turno (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255) NOT NULL
);

------------------------------------------------------------
-- CURSO Y RELACIONADOS
------------------------------------------------------------

CREATE TABLE DROP_DATABASE.Curso (
    codigoCurso BIGINT IDENTITY(1,1) PRIMARY KEY,
    sedeId INT NOT NULL REFERENCES DROP_DATABASE.Sede(id),
    profesorId Bigint NOT NULL REFERENCES DROP_DATABASE.Profesor(id),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(255) NOT NULL,
    categoriaId BIGINT NOT NULL REFERENCES DROP_DATABASE.Categoria(id),
    fechaInicio DATETIME2(6) NOT NULL,
    fechaFin DATETIME2(6) NOT NULL,
    duracion AS DATEDIFF(MONTH, fechaInicio, fechaFin) PERSISTED,
    turnoId INT NOT NULL REFERENCES DROP_DATABASE.Turno(id),
    precioMensual DECIMAL(18,2)
);

CREATE TABLE DROP_DATABASE.Modulo (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(255),
    descripcion NVARCHAR(255)
);

CREATE TABLE DROP_DATABASE.Modulo_x_Curso (
    id INT IDENTITY(1,1) PRIMARY KEY,
    cursoId BIGINT NOT NULL REFERENCES DROP_DATABASE.Curso(codigoCurso),
    moduloId INT NOT NULL REFERENCES DROP_DATABASE.Modulo(id)
);

CREATE TABLE DROP_DATABASE.Dia_Semana (
    id INT IDENTITY(1,1) PRIMARY KEY,
    dia NVARCHAR(255) NOT NULL
);

CREATE TABLE DROP_DATABASE.Dia_Cursado (
    diaSemanaId INT NOT NULL REFERENCES DROP_DATABASE.Dia_Semana(id),
    codigoCurso BIGINT NOT NULL REFERENCES DROP_DATABASE.Curso(codigoCurso)
    CONSTRAINT pk_dia_Semana_Curso PRIMARY KEY (diaSemanaId, codigoCurso)
);

USE GD2C2025;
GO

-- ALUMNO--ELISEO
CREATE TABLE DROP_DATABASE.Alumno (
    legajoAlumno BIGINT PRIMARY KEY,
    nombre NVARCHAR(255) NOT NULL,
    apellido NVARCHAR(255) NOT NULL,
    dni INT NULL,
    localidad_id INT NULL,
    domicilio NVARCHAR(255) NULL,
    fechaNacimiento DATETIME2(6) NULL,
    direccion NVARCHAR(255) NULL,
    mail NVARCHAR(255) NULL,
    telefono NVARCHAR(255) NULL,
    CONSTRAINT FK_Alumno_Localidad FOREIGN KEY (localidad_id)
        REFERENCES DROP_DATABASE.Localidad(id)
);
GO

INSERT INTO DROP_DATABASE.Alumno (legajoAlumno, nombre, apellido, dni, localidad_id, domicilio, fechaNacimiento, direccion, mail, telefono)
SELECT DISTINCT
        Alumno_Legajo,
        Alumno_Nombre,
        Alumno_Apellido,
        Alumno_Dni,
        l.id AS localidad_id,
        Alumno_Domicilio,
        Alumno_FechaNacimiento,
        Alumno_Direccion,
        Alumno_Mail,
        Alumno_Telefono
    FROM gd_esquema.Maestra m
        LEFT JOIN DROP_DATABASE.Localidad l ON l.nombre = m.Alumno_Localidad
WHERE Alumno_Legajo IS NOT NULL;
--AL EJECUTAR EL SCRIPT SE TIENE QUE TENER EN CUENTA EL ORDEN DE GUARDADO DE DATOS
-- PARA QUE NO HAYA PROBLEMAS DE FK DEBIDO A QUE ALGUNOS DATOS DE ALUMNO DEPENDEN DE OTRAS TABLAS


-- TP_ALUMNO (evaluaciones parciales / trabajos prácticos)
CREATE TABLE DROP_DATABASE.TP_Alumno (
    id INT IDENTITY(1,1) PRIMARY KEY,
    legajoAlumno BIGINT NOT NULL,
    nota BIGINT NULL,
    fechaEvaluacion DATETIME2(6) NULL,
    curso BIGINT NOT NULL,
    CONSTRAINT FK_TPAlumno_Alumno FOREIGN KEY (legajoAlumno)
        REFERENCES DROP_DATABASE.Alumno(legajoAlumno),
    CONSTRAINT FK_TPAlumno_Curso FOREIGN KEY (curso)
        REFERENCES DROP_DATABASE.Curso(codigoCurso)
);
GO
INSERT INTO DROP_DATABASE.TP_Alumno (legajoAlumno, nota, fechaEvaluacion, curso)
SELECT DISTINCT
        a.legajoAlumno,
        m.TP_Alumno_Nota,
        m.TP_Alumno_FechaEvaluacion,
        c.codigoCurso
    FROM gd_esquema.Maestra m
        INNER JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = m.Alumno_Legajo
        INNER JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
WHERE m.TP_Alumno_FechaEvaluacion IS NOT NULL;

-- INSCRIPCION A CURSO
CREATE TABLE DROP_DATABASE.Inscripcion_Curso (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fechaInscripcion DATETIME2(6) NOT NULL DEFAULT (SYSDATETIME()),
    legajoAlumno BIGINT NOT NULL, 
    codigoCurso BIGINT NOT NULL,
    estado NVARCHAR(255) NULL Default ('pendiente'),
    fechaRespuesta DATETIME2(6) NULL,
    CONSTRAINT FK_InscripcionCurso_Alumno FOREIGN KEY (legajoAlumno)
        REFERENCES DROP_DATABASE.Alumno(legajoAlumno),
    CONSTRAINT FK_InscripcionCurso_Curso FOREIGN KEY (codigoCurso)
        REFERENCES DROP_DATABASE.Curso(codigoCurso)
);
GO
INSERT INTO DROP_DATABASE.Inscripcion_Curso (legajoAlumno, codigoCurso, estado, fechaRespuesta)
SELECT DISTINCT
        a.legajoAlumno,
        c.codigoCurso,
        m.Inscripcion_Curso_Estado,
        m.Inscripcion_Curso_FechaRespuesta
    FROM gd_esquema.Maestra m
        INNER JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = m.Alumno_Legajo
        INNER JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
WHERE m.Inscripcion_Curso_Estado IS NOT NULL;

-- FINAL (mesa de examen)
CREATE TABLE DROP_DATABASE.Final (
    idFinal BIGINT PRIMARY KEY,
    fecha DATETIME2(6) NULL,
    hora NVARCHAR(255) NULL,
    curso BIGINT NULL,
    descripcion NVARCHAR(255) NULL,
    CONSTRAINT FK_Final_Curso FOREIGN KEY (curso)
        REFERENCES DROP_DATABASE.Curso(codigoCurso)
);
GO
INSERT INTO DROP_DATABASE.Final (idFinal, fecha, hora, curso, descripcion)
SELECT DISTINCT
        m.Final_IdFinal,
        m.Final_Fecha,
        m.Final_Hora,
        c.codigoCurso,
        m.Final_Descripcion
    FROM gd_esquema.Maestra m
        INNER JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
WHERE m.Final_IdFinal IS NOT NULL;

-- FINAL RENDIDO (registro de alumno en un final)
CREATE TABLE DROP_DATABASE.Final_rendido (
    id BIGINT PRIMARY KEY,
    legajoAlumno BIGINT NOT NULL,
    finalId BIGINT NOT NULL,
    presente BIT NULL,
    nota BIGINT NULL,
    profesor BIGINT NULL,     
    CONSTRAINT FK_FinalRendido_Alumno FOREIGN KEY (legajoAlumno)
        REFERENCES DROP_DATABASE.Alumno(legajoAlumno),
    CONSTRAINT FK_FinalRendido_Final FOREIGN KEY (finalId)
        REFERENCES DROP_DATABASE.Final(idFinal),
    CONSTRAINT FK_FinalRendido_Profesor FOREIGN KEY (profesor)
        REFERENCES DROP_DATABASE.Profesor(id)
);
GO
INSERT INTO DROP_DATABASE.Final_rendido (id, legajoAlumno, finalId, presente, nota, profesor)
SELECT DISTINCT
        m.Final_Rendido_Id,
        a.legajoAlumno,
        f.idFinal,
        m.Final_Rendido_Presente,
        m.Final_Rendido_Nota,
        p.id AS profesor
    FROM gd_esquema.Maestra m
        INNER JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = m.Alumno_Legajo
        INNER JOIN DROP_DATABASE.Final f ON f.idFinal = m.Final_Rendido_FinalId
        LEFT JOIN DROP_DATABASE.Profesor p ON p.dni = m.Final_Rendido_Profesor_Dni
WHERE m.Final_Rendido_Id IS NOT NULL;

-- INSCRIPCION A FINAL
CREATE TABLE DROP_DATABASE.Inscripcion_Final (
    InscripcionFinalId BIGINT PRIMARY KEY,
    legajoAlumno BIGINT NOT NULL,
    fechaInscripcion DATETIME2(6) NOT NULL
        CONSTRAINT DF_InscripcionFinal_Fecha DEFAULT (SYSDATETIME()),
    finalId BIGINT NOT NULL,
    presente BIT NULL,
    profesor BIGINT NULL,
    CONSTRAINT FK_InscripcionFinal_Alumno FOREIGN KEY (legajoAlumno)
        REFERENCES DROP_DATABASE.Alumno(legajoAlumno),
    CONSTRAINT FK_InscripcionFinal_Final FOREIGN KEY (finalId)
        REFERENCES DROP_DATABASE.Final(idFinal),
    CONSTRAINT FK_InscripcionFinal_Profesor FOREIGN KEY (profesor)
        REFERENCES DROP_DATABASE.Profesor(id)
);
GO
INSERT INTO DROP_DATABASE.Inscripcion_Final (InscripcionFinalId, legajoAlumno, fechaInscripcion, finalId, presente, profesor)
SELECT DISTINCT
        m.Inscripcion_Final_Id,
        a.legajoAlumno,
        m.Inscripcion_Final_FechaInscripcion,
        f.idFinal,
        m.Inscripcion_Final_Presente,
        p.id AS profesor
    FROM gd_esquema.Maestra m
        INNER JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = m.Alumno_Legajo
        INNER JOIN DROP_DATABASE.Final f ON f.idFinal = m.Inscripcion_Final_FinalId
        LEFT JOIN DROP_DATABASE.Profesor p ON p.dni = m.Inscripcion_Final_Profesor_Dni
WHERE m.Inscripcion_Final_Id IS NOT NULL;

------------------------------------------------------------
-- ENCUESTAS
------------------------------------------------------------

CREATE TABLE DROP_DATABASE.Encuesta (
    encuestaId INT IDENTITY(1,1) PRIMARY KEY,
    cursoId BIGINT NOT NULL REFERENCES DROP_DATABASE.Curso(codigoCurso)
);

CREATE TABLE DROP_DATABASE.Pregunta (
    id INT IDENTITY(1,1) PRIMARY KEY,
    pregunta NVARCHAR(255),
    encuestaId INT NOT NULL REFERENCES DROP_DATABASE.Encuesta(encuestaId)
);

CREATE TABLE DROP_DATABASE.Encuesta_Respondida (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fechaRegistro DATETIME2(6) default(sysdatetime()),
    encuestaObservacion NVARCHAR(255) NOT NULL,
    encuestaId INT NOT NULL REFERENCES DROP_DATABASE.Encuesta(encuestaId)
);

CREATE TABLE DROP_DATABASE.Detalle (
    id INT IDENTITY(1,1) PRIMARY KEY,
    preguntaId INT NOT NULL REFERENCES DROP_DATABASE.Pregunta(id),
    respuestaNota BIGINT CHECK (respuestaNota BETWEEN 1 AND 10),
    encuestaRespondidaId INT NOT NULL REFERENCES DROP_DATABASE.Encuesta_Respondida(id)
);


-- Mariano

CREATE TABLE DROP_DATABASE.Medio_Pago (
    id INT IDENTITY(1,1) PRIMARY KEY,
    medioPago VARCHAR(255) NOT NULL
);
GO

insert into DROP_DATABASE.Medio_Pago
select DISTINCT Pago_MedioPago from gd_esquema.Maestra
GO

CREATE TABLE DROP_DATABASE.Factura (
    facturaNumero BIGINT PRIMARY KEY NOT NULL,
    fechaEmision DATETIME2(6) NOT NULL,
    fechaVencimiento DATETIME2(6) NOT NULL,
    importeTotal DECIMAL(18,2) NOT NULL,
    legajoAlumno BIGINT NOT NULL,
    CONSTRAINT fk_legajoAlumno
        FOREIGN KEY (legajoAlumno) REFERENCES DROP_DATABASE.Alumno(legajoAlumno)
);
GO

insert into DROP_DATABASE.Factura
select DISTINCT
        f.Factura_Numero,
        f.Factura_FechaEmision,
        f.Factura_FechaVencimiento,
        f.Factura_Total,
        a.legajoAlumno
    from gd_esquema.Maestra f
        inner join DROP_DATABASE.Alumno a on a.legajoAlumno = f.Alumno_Legajo;
GO

CREATE TABLE DROP_DATABASE.Pago (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATETIME2(6) NOT NULL,
    importe DECIMAL(18, 2) NOT NULL,
    medioPagoId INT NOT NULL,
    facturaNumero BIGINT NOT NULL,  
    CONSTRAINT fk_medioPagoId
        FOREIGN KEY (medioPagoId) REFERENCES DROP_DATABASE.Medio_Pago(id),
    CONSTRAINT fk_facturaId
        FOREIGN KEY (facturaNumero) REFERENCES DROP_DATABASE.Factura(facturaNumero)
);
GO

insert into DROP_DATABASE.Pago
select DISTINCT
        m.Pago_Fecha,
        m.Pago_Importe,
        mp.id AS medioPagoId, 
        f.facturaNumero
    from gd_esquema.Maestra m
        INNER JOIN DROP_DATABASE.Medio_Pago mp ON mp.medioPago = m.Pago_MedioPago
        INNER JOIN DROP_DATABASE.Factura f ON f.facturaNumero = m.Factura_Numero;
GO

CREATE TABLE DROP_DATABASE.Periodo (
    id INT IDENTITY(1,1) PRIMARY KEY,
    periodoAnio BIGINT default(year(sysdatetime())),
    periodoMes BIGINT default(month(sysdatetime()))
);
GO

insert into DROP_DATABASE.Periodo
select DISTINCT
        Periodo_Anio, Periodo_Mes
    from gd_esquema.Maestra;
GO


CREATE TABLE DROP_DATABASE.Detalle_Factura (
    id INT IDENTITY(1,1) PRIMARY KEY,
    codigoCurso BIGINT NOT NULL,
    importe DECIMAL(18, 2) NOT NULL,
    facturaNumero BIGINT NOT NULL,
    periodoId INT NOT NULL,
    CONSTRAINT fk_codigoCurso
        FOREIGN KEY (codigoCurso) REFERENCES DROP_DATABASE.Curso(codigoCurso),
    CONSTRAINT fk_facturaId
        FOREIGN KEY (facturaNumero) REFERENCES DROP_DATABASE.Factura(facturaNumero),
    CONSTRAINT fk_periodoId
        FOREIGN KEY (periodoId) REFERENCES DROP_DATABASE.Periodo(id)
);
GO

insert into DROP_DATABASE.Detalle_Factura
select DISTINCT
        c.codigoCurso,
        m.Detalle_Factura_Importe,
        f.facturaNumero, 
        p.id
    from gd_esquema.Maestra m
        INNER JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
        INNER JOIN DROP_DATABASE.Factura f ON f.facturaNumero = m.Factura_Numero
        inner join DROP_DATABASE.Periodo p on p.periodoAnio = m.Periodo_Anio and p.periodoMes = m.Periodo_Mes;
GO

CREATE TABLE DROP_DATABASE.Evaluacion (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATETIME2(6) NOT NULL
);
GO

insert into DROP_DATABASE.Evaluacion
SELECT DISTINCT Evaluacion_Curso_fechaEvaluacion
    FROM gd_esquema.Maestra
WHERE Evaluacion_Curso_fechaEvaluacion IS NOT NULL;
GO

CREATE TABLE DROP_DATABASE.Evaluacion_Rendida (
    id INT IDENTITY(1,1) PRIMARY KEY,
    legajoAlumno BIGINT NOT NULL,
    nota BIGINT NULL,           -- Puede ser NULL si no se evaluó
    presente BIT NOT NULL,
    instancia BIGINT NOT NULL,
    evaluacionId INT NOT NULL,
    CONSTRAINT fk_evaluacionId
        FOREIGN KEY (evaluacionId) REFERENCES DROP_DATABASE.Evaluacion(id),
    CONSTRAINT fk_legajoAlumno
        FOREIGN KEY (legajoAlumno) REFERENCES DROP_DATABASE.Alumno(legajoAlumno)
);
GO

insert into DROP_DATABASE.Evaluacion_Rendida
select DISTINCT
        a.legajoAlumno,
        m.Evaluacion_Curso_Nota,
        m.Evaluacion_Curso_Presente,
        m.Evaluacion_Curso_Instancia,
        e.id
    from gd_esquema.Maestra m
        inner join DROP_DATABASE.Alumno a on a.legajoAlumno = m.Alumno_Legajo
        inner join DROP_DATABASE.Evaluacion e on e.fecha = m.Evaluacion_Curso_fechaEvaluacion;
go

CREATE TABLE DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion (
    evaluacionId INT NOT NULL,
    moduloCursoId INT NOT NULL,
    CONSTRAINT pk_modulo_eval PRIMARY KEY (evaluacionId, moduloCursoId),
    CONSTRAINT fk_evalId
        FOREIGN KEY (evaluacionId) REFERENCES DROP_DATABASE.Evaluacion(id),
    CONSTRAINT fk_modulo
        FOREIGN KEY (moduloCursoId) REFERENCES DROP_DATABASE.Modulo_x_Curso(id)
);
GO

insert into DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion
select DISTINCT
        e.id,
        mxc.id
    FROM gd_esquema.Maestra maestra
        INNER JOIN DROP_DATABASE.Evaluacion e ON e.Fecha = maestra.Evaluacion_Curso_fechaEvaluacion
        INNER JOIN DROP_DATABASE.Modulo m ON m.nombre = maestra.Modulo_Nombre
        INNER JOIN DROP_DATABASE.Curso c ON c.codigoCurso = maestra.Curso_Codigo
        INNER JOIN DROP_DATABASE.Modulo_X_Curso mxc ON mxc.moduloid = m.id AND mxc.cursoid = c.codigoCurso
WHERE maestra.Evaluacion_Curso_fechaEvaluacion IS NOT NULL
    AND maestra.Modulo_Nombre IS NOT NULL
    AND maestra.Curso_Codigo IS NOT NULL;


--------------------------------------------------------------
-- TRIGGERS
--------------------------------------------------------------
go;
CREATE TRIGGER DROP_DATABASE.trg_validarRangoFechasCurso ON DROP_DATABASE.Curso
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE fechaInicio > fechaFin
    )
    BEGIN
        RAISERROR('La fecha de inicio no puede ser posterior a la fecha de fin.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

go;


go;

CREATE TRIGGER DROP_DATABASE.trg_fecha_cambio_estado_inscripcion
ON DROP_DATABASE.Inscripcion_Curso
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ic
    SET ic.fechaRespuesta = SYSDATETIME()
    FROM DROP_DATABASE.Inscripcion_Curso ic
    INNER JOIN inserted i ON ic.id = i.id
    INNER JOIN deleted d ON i.id = d.id
    WHERE ISNULL(i.estado, '') <> ISNULL(d.estado, '');
END;
GO

--trigger que calcula y modifica la intancia de parcial en base a la cantidad de veces que este alumno intento rendir 
-- como me doy cuenta? seleccionando todas las evaliaciones que tengan TODOS los modulos tomados por la evaluacion actual 
--y contando en cuales de ellas existe una evaluacion rendida por el alumno  

CREATE TRIGGER DROP_DATABASE.trg_asignarInstanciaParcial
ON DROP_DATABASE.Evaluacion_Rendida
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE er
    SET instancia = (
        SELECT COUNT(*) 
        FROM DROP_DATABASE.Evaluacion_Rendida er2
        WHERE er2.legajoAlumno = i.legajoAlumno
          AND er2.id < i.id  -- evita contar la evaluación recién insertada
          AND NOT EXISTS (   -- asegura que no falte ningún módulo de la evaluación actual
                SELECT 1
                FROM DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion mx
                WHERE mx.evaluacionId = i.evaluacionId
                AND NOT EXISTS (
                    SELECT 1 
                    FROM DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion mx2
                    WHERE mx2.evaluacionId = er2.evaluacionId
                      AND mx2.moduloCursoId = mx.moduloCursoId
                )
          )
    )
    FROM DROP_DATABASE.Evaluacion_Rendida er
    INNER JOIN inserted i ON er.id = i.id;
END;
GO;

CREATE TRIGGER DROP_DATABASE.trg_unicaInscripcion
ON DROP_DATABASE.Inscripcion_Curso
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DROP_DATABASE.Inscripcion_Curso ic
        JOIN inserted i ON ic.legajoAlumno = i.legajoAlumno AND ic.codigoCurso = i.codigoCurso
    )
    BEGIN
        RAISERROR('El alumno ya está inscripto en este curso.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO DROP_DATABASE.Inscripcion_Curso (fechaInscripcion, legajoAlumno, codigoCurso, estado)
    SELECT fechaInscripcion, legajoAlumno, codigoCurso, estado FROM inserted;
END;


GO;
---------------------------------------------------
--index
---------------------------------------------------
CREATE INDEX IX_Inscripcion_Curso_Alumno ON DROP_DATABASE.Inscripcion_Curso(legajoAlumno);
CREATE INDEX IX_Inscripcion_Curso_Curso ON DROP_DATABASE.Inscripcion_Curso(codigoCurso);
CREATE INDEX IX_TP_Alumno_Curso ON DROP_DATABASE.TP_Alumno(curso);
CREATE INDEX IX_Factura_Alumno ON DROP_DATABASE.Factura(legajoAlumno);
CREATE INDEX IX_Pago_Factura ON DROP_DATABASE.Pago(id);

---------------------------------------------------
--constraints
---------------------------------------------------

ALTER TABLE DROP_DATABASE.Curso
ADD CONSTRAINT CK_Curso_PrecioPositivo CHECK (precioMensual >= 0);

ALTER TABLE DROP_DATABASE.Final_rendido
ADD CONSTRAINT CK_FinalRendido_NotaValida CHECK (nota BETWEEN 1 AND 10 OR nota IS NULL);

    

go; 

----------------------------------------------------------
-- Inserts
----------------------------------------------------------

INSERT INTO DROP_DATABASE.Institucion (nombre, razonSocial, cuit)
SELECT DISTINCT Institucion_Nombre, Institucion_RazonSocial, Institucion_Cuit
FROM gd_esquema.Maestra
WHERE Institucion_Nombre IS NOT NULL;

INSERT INTO DROP_DATABASE.Turno (nombre)
SELECT DISTINCT Curso_Turno FROM gd_esquema.Maestra
WHERE Curso_Turno IS NOT NULL;

INSERT INTO DROP_DATABASE.Dia_Semana (dia)
SELECT DISTINCT Curso_Dia FROM gd_esquema.Maestra
WHERE Curso_Dia IS NOT NULL;


-- Acá hay que ver si para código curso usamos el que ya viene en la tabla maestra
-- (como en este código) o si usamos IDENTITY como está definido la PK de Curso.
INSERT INTO DROP_DATABASE.Dia_Cursado (diaSemanaId, codigoCurso)
SELECT DISTINCT ds.id, Curso_Codigo FROM gd_esquema.Maestra
    JOIN DROP_DATABASE.Dia_Semana ds ON ds.dia = Curso_Dia

------------------------------------------------------------
-- Cargar las provincias
------------------------------------------------------------

-- Cuidado, los datos que tiene la tabla maestra en Sede_Provincia por algún motivo no son provincias argentinas.
-- Pero si no se insertan, no van a aparecer 2 Sedes
INSERT INTO DROP_DATABASE.Provincia (nombre)
SELECT DISTINCT Sede_Provincia
FROM gd_esquema.Maestra
WHERE Sede_Provincia IS NOT NULL
    AND Sede_Provincia NOT IN (SELECT nombre FROM DROP_DATABASE.Provincia);

INSERT INTO DROP_DATABASE.Provincia (nombre)
SELECT DISTINCT Profesor_Provincia
FROM gd_esquema.Maestra
WHERE Profesor_Provincia IS NOT NULL
    AND Profesor_Provincia NOT IN (SELECT nombre FROM DROP_DATABASE.Provincia);

INSERT INTO DROP_DATABASE.Provincia (nombre)
SELECT DISTINCT Alumno_Provincia
FROM gd_esquema.Maestra
WHERE Alumno_Provincia IS NOT NULL
    AND Alumno_Provincia NOT IN (SELECT nombre FROM DROP_DATABASE.Provincia);

------------------------------------------------------------
-- Cargar las localidades
------------------------------------------------------------

INSERT INTO DROP_DATABASE.Localidad (nombre, provinciaId)
SELECT DISTINCT Sede_Localidad, p.id
FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Provincia p ON p.nombre = m.Sede_Provincia
WHERE m.Sede_Localidad IS NOT NULL
    AND m.Sede_Localidad NOT IN (SELECT nombre FROM DROP_DATABASE.Localidad);

INSERT INTO DROP_DATABASE.Localidad (nombre, provinciaId)
SELECT DISTINCT m.Profesor_Localidad, p.id
FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Provincia p ON p.nombre = m.Profesor_Provincia
WHERE m.Profesor_Localidad IS NOT NULL
    AND m.Profesor_Localidad NOT IN (SELECT nombre FROM DROP_DATABASE.Localidad);

-- Acá hay algunos datos rotos. Por ejemplo pone ";bernador Andonaeghi", ";doy"
-- Pueden probar ejecutando el select sin la línea del insert
INSERT INTO DROP_DATABASE.Localidad (nombre, provinciaId)
SELECT DISTINCT m.Alumno_Localidad, p.id
FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Provincia p ON p.nombre = m.Alumno_Provincia
WHERE m.Alumno_Localidad IS NOT NULL
    AND m.Alumno_Localidad NOT IN (SELECT nombre FROM DROP_DATABASE.Localidad);

INSERT INTO DROP_DATABASE.Sede (nombre, telefono, direccion, mail, localidadId, institucionId)
SELECT DISTINCT 
    Sede_Nombre,
    Sede_Telefono,
    Sede_Direccion,
    Sede_Mail,
    l.id,
    i.id
FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Provincia p ON p.nombre = Sede_Provincia
    JOIN DROP_DATABASE.Localidad l ON l.nombre = m.Sede_Localidad AND l.provinciaId = p.id
    JOIN DROP_DATABASE.Institucion i ON i.nombre = m.Institucion_Nombre
WHERE m.Sede_Nombre IS NOT NULL;

INSERT INTO DROP_DATABASE.Profesor (localidadId, apellido, nombre, dni, fechaNacimiento, direccion, telefono, mail)
SELECT DISTINCT 
    l.id,
    m.Profesor_Apellido,
    m.Profesor_Nombre,
    m.Profesor_Dni,
    m.Profesor_FechaNacimiento,
    m.Profesor_Direccion,
    m.Profesor_Telefono,
    m.Profesor_Mail
FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Localidad l ON l.nombre = m.Profesor_Localidad


