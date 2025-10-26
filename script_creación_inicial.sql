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
    provincia_id INT NOT NULL 
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
    localidad_id INT NOT NULL REFERENCES DROP_DATABASE.Localidad(id),
    mail NVARCHAR(255),
    institucion_id INT NOT NULL REFERENCES DROP_DATABASE.Institucion(id)
);

CREATE TABLE DROP_DATABASE.Profesor (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    localidad_id INT NOT NULL REFERENCES DROP_DATABASE.Localidad(id),
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
    duracion BIGINT NOT NULL,
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
    id INT IDENTITY(1,1) PRIMARY KEY,
    diaSemanal_id INT NOT NULL REFERENCES DROP_DATABASE.Dia_Semana(id),
    codigoCurso BIGINT NOT NULL REFERENCES DROP_DATABASE.Curso(codigoCurso)
);

USE GD2C2025;
GO

-- ALUMNO
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
    fechaRegistro DATETIME2(6) NOT NULL,
    encuestaObservacion NVARCHAR(255) NOT NULL,
    encuestaId INT NOT NULL REFERENCES DROP_DATABASE.Encuesta(encuestaId)
);

CREATE TABLE DROP_DATABASE.Detalle (
    id INT IDENTITY(1,1) PRIMARY KEY,
    preguntaId INT NOT NULL REFERENCES DROP_DATABASE.Pregunta(id),
    respuestaNota BIGINT NOT NULL,
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
    periodoAnio BIGINT NOT NULL,
    periodoMes BIGINT NOT NULL
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
    id INT IDENTITY(1,1) PRIMARY KEY,
    evaluacionId INT NOT NULL,
    modulo INT NOT NULL,
    CONSTRAINT fk_evalId
        FOREIGN KEY (evaluacionId) REFERENCES DROP_DATABASE.Evaluacion(id),
    CONSTRAINT fk_modulo
        FOREIGN KEY (modulo) REFERENCES DROP_DATABASE.Modulo_x_Curso(id)
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
CREATE TRIGGER trg_validarRangoFechasCurso ON DROP_DATABASE.Curso
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
ALTER TABLE DROP_DATABASE.Curso
ADD CONSTRAINT DF_Curso_DuracionDefault DEFAULT (DATEDIFF(MONTH, fechaInicio, fechaFin)) FOR duracion;


go;
CREATE TRIGGER trg_validarDuracionCurso ON DROP_DATABASE.Curso
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE DATEDIFF(MONTH, fechaInicio, fechaFin)!=duracion
    )
    BEGIN
        RAISERROR('La duracion no coincide con la diferencia de meses entre las fechas de inicio y fin.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

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
    

go; 
select * from GD2C2025.gd_esquema.Maestra


