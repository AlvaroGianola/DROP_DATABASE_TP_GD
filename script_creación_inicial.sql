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
    provinciaId INT NOT NULL REFERENCES DROP_DATABASE.Provincia(id)
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

CREATE TABLE DROP_DATABASE.Dia_Semana (
    id INT IDENTITY(1,1) PRIMARY KEY,
    dia NVARCHAR(255) NOT NULL
);

CREATE TABLE DROP_DATABASE.Curso (
    codigoCurso BIGINT IDENTITY(1,1) PRIMARY KEY,
    sedeId INT NOT NULL REFERENCES DROP_DATABASE.Sede(id),
    profesorId BIGINT NOT NULL REFERENCES DROP_DATABASE.Profesor(id),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(255) NOT NULL,
    categoriaId BIGINT NOT NULL REFERENCES DROP_DATABASE.Categoria(id),
    fechaInicio DATETIME2(6) NOT NULL,
    fechaFin DATETIME2(6) NOT NULL,
    duracion AS DATEDIFF(MONTH, fechaInicio, fechaFin) PERSISTED,
    turnoId INT NOT NULL REFERENCES DROP_DATABASE.Turno(id),
    precioMensual DECIMAL(18,2)
);

CREATE TABLE DROP_DATABASE.Dia_Cursado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    diaSemanaId INT NOT NULL REFERENCES DROP_DATABASE.Dia_Semana(id),
    codigoCurso BIGINT NOT NULL REFERENCES DROP_DATABASE.Curso(codigoCurso)
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

------------------------------------------------------------
-- ALUMNO
------------------------------------------------------------

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
    estado NVARCHAR(255) NULL DEFAULT ('pendiente'),
    fechaRespuesta DATETIME2(6) NULL,
    CONSTRAINT FK_InscripcionCurso_Alumno FOREIGN KEY (legajoAlumno)
        REFERENCES DROP_DATABASE.Alumno(legajoAlumno),
    CONSTRAINT FK_InscripcionCurso_Curso FOREIGN KEY (codigoCurso)
        REFERENCES DROP_DATABASE.Curso(codigoCurso)
);
GO

-- FINAL
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

-- FINAL RENDIDO
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
    fechaInscripcion DATETIME2(6) NOT NULL CONSTRAINT DF_InscripcionFinal_Fecha DEFAULT (SYSDATETIME()),
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
    nroPregunta INT CHECK (nroPregunta BETWEEN 1 AND 4),
    encuestaId INT NOT NULL REFERENCES DROP_DATABASE.Encuesta(encuestaId)
);

CREATE TABLE DROP_DATABASE.Encuesta_Respondida (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fechaRegistro DATETIME2(6) DEFAULT (SYSDATETIME()),
    encuestaObservacion NVARCHAR(255) NOT NULL,
    encuestaId INT NOT NULL REFERENCES DROP_DATABASE.Encuesta(encuestaId)
);

CREATE TABLE DROP_DATABASE.Detalle_Encuesta_Respondida (
    id INT IDENTITY(1,1) PRIMARY KEY,
    preguntaId INT NOT NULL REFERENCES DROP_DATABASE.Pregunta(id),
    respuestaNota BIGINT CHECK (respuestaNota BETWEEN 1 AND 10),
    encuestaRespondidaId INT NOT NULL REFERENCES DROP_DATABASE.Encuesta_Respondida(id)
);

------------------------------------------------------------
-- PAGOS Y FACTURAS
------------------------------------------------------------

CREATE TABLE DROP_DATABASE.Medio_Pago (
    id INT IDENTITY(1,1) PRIMARY KEY,
    medioPago VARCHAR(255) NOT NULL
);

CREATE TABLE DROP_DATABASE.Factura (
    facturaNumero BIGINT PRIMARY KEY NOT NULL,
    fechaEmision DATETIME2(6) NOT NULL,
    fechaVencimiento DATETIME2(6) NOT NULL,
    importeTotal DECIMAL(18,2) NOT NULL,
    legajoAlumno BIGINT NOT NULL,
    CONSTRAINT fk_legajoAlumno FOREIGN KEY (legajoAlumno) REFERENCES DROP_DATABASE.Alumno(legajoAlumno)
);

CREATE TABLE DROP_DATABASE.Pago (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATETIME2(6) NOT NULL DEFAULT (SYSDATETIME()),
    importe DECIMAL(18,2) NOT NULL,
    medioPagoId INT NOT NULL,
    facturaNumero BIGINT NOT NULL,
    CONSTRAINT fk_medioPagoId FOREIGN KEY (medioPagoId) REFERENCES DROP_DATABASE.Medio_Pago(id),
    CONSTRAINT fk_facturaId FOREIGN KEY (facturaNumero) REFERENCES DROP_DATABASE.Factura(facturaNumero)
);

CREATE TABLE DROP_DATABASE.Periodo (
    id INT IDENTITY(1,1) PRIMARY KEY,
    periodoAnio BIGINT DEFAULT (YEAR(SYSDATETIME())),
    periodoMes BIGINT DEFAULT (MONTH(SYSDATETIME()))
);

CREATE TABLE DROP_DATABASE.Detalle_Factura (
    id INT IDENTITY(1,1) PRIMARY KEY,
    codigoCurso BIGINT NOT NULL REFERENCES DROP_DATABASE.Curso(codigoCurso),
    importe DECIMAL(18,2) NOT NULL,
    facturaNumero BIGINT NOT NULL REFERENCES DROP_DATABASE.Factura(facturaNumero),
    periodoId INT NOT NULL REFERENCES DROP_DATABASE.Periodo(id)
);

------------------------------------------------------------
-- EVALUACIONES
------------------------------------------------------------

CREATE TABLE DROP_DATABASE.Evaluacion (
    id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATETIME2(6) NOT NULL,
    cursoId BIGINT NULL REFERENCES DROP_DATABASE.Curso(codigoCurso)
);

CREATE TABLE DROP_DATABASE.Evaluacion_Rendida (
    id INT IDENTITY(1,1) PRIMARY KEY,
    legajoAlumno BIGINT NOT NULL,
    nota BIGINT NULL,
    presente BIT NOT NULL,
    instancia BIGINT NULL,
    evaluacionId INT NOT NULL REFERENCES DROP_DATABASE.Evaluacion(id),
    CONSTRAINT fk_legajoAlumno FOREIGN KEY (legajoAlumno) REFERENCES DROP_DATABASE.Alumno(legajoAlumno)
);

CREATE TABLE DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion (
    id INT IDENTITY(1,1) PRIMARY KEY,
    evaluacionId INT NOT NULL REFERENCES DROP_DATABASE.Evaluacion(id),
    modulo INT NOT NULL REFERENCES DROP_DATABASE.Modulo_x_Curso(id)
);

--------------------------------------------------------------
-- TRIGGERS
--------------------------------------------------------------

GO
CREATE TRIGGER DROP_DATABASE.trg_validarRangoFechasCurso ON DROP_DATABASE.Curso
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE fechaInicio > fechaFin)
    BEGIN
        RAISERROR('La fecha de inicio no puede ser posterior a la fecha de fin.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

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
          AND er2.id < i.id
          AND NOT EXISTS (
                SELECT 1
                FROM DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion mx
                WHERE mx.evaluacionId = i.evaluacionId
                AND NOT EXISTS (
                    SELECT 1 
                    FROM DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion mx2
                    WHERE mx2.evaluacionId = er2.evaluacionId
                      AND mx2.modulo = mx.modulo
                )
          )
    )
    FROM DROP_DATABASE.Evaluacion_Rendida er
    INNER JOIN inserted i ON er.id = i.id;
END;
GO

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
GO

---------------------------------------------------
-- INDEXES Y CONSTRAINTS ADICIONALES
---------------------------------------------------

CREATE INDEX IX_Inscripcion_Curso_Alumno ON DROP_DATABASE.Inscripcion_Curso(legajoAlumno);
CREATE INDEX IX_Inscripcion_Curso_Curso ON DROP_DATABASE.Inscripcion_Curso(codigoCurso);
CREATE INDEX IX_TP_Alumno_Curso ON DROP_DATABASE.TP_Alumno(curso);
CREATE INDEX IX_Factura_Alumno ON DROP_DATABASE.Factura(legajoAlumno);
CREATE INDEX IX_Pago_Factura ON DROP_DATABASE.Pago(id);

ALTER TABLE DROP_DATABASE.Curso
ADD CONSTRAINT CK_Curso_PrecioPositivo CHECK (precioMensual >= 0);

ALTER TABLE DROP_DATABASE.Final_rendido
ADD CONSTRAINT CK_FinalRendido_NotaValida CHECK (nota BETWEEN 1 AND 10 OR nota IS NULL);
GO

---------------------------------------------------
-- MIGRACIÓN DE DATOS
---------------------------------------------------

BEGIN TRY
    BEGIN TRANSACTION;

    -- acá van tus INSERTS desde gd_esquema.Maestra (ya corregidos en tu versión anterior)

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en migración: ' + ERROR_MESSAGE();
END CATCH;
GO
