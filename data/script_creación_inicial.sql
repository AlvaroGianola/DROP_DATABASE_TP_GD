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
GO
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
    Inscripcion_Numero BIGINT identity(1,1) PRIMARY KEY,  -- ESTA ES LA PK REAL
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
    Final_Nro BIGINT identity (1,1) PRIMARY KEY,  
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
    id BIGINT identity(1,1)PRIMARY KEY,
    legajoAlumno BIGINT NOT NULL,
    finalId BIGINT NOT NULL,
    presente BIT NULL,
    nota BIGINT NULL,
    profesor BIGINT NULL,     
    CONSTRAINT FK_FinalRendido_Alumno FOREIGN KEY (legajoAlumno)
        REFERENCES DROP_DATABASE.Alumno(legajoAlumno),
    CONSTRAINT FK_FinalRendido_Final FOREIGN KEY (finalId)
        REFERENCES DROP_DATABASE.Final(Final_Nro),
    CONSTRAINT FK_FinalRendido_Profesor FOREIGN KEY (profesor)
        REFERENCES DROP_DATABASE.Profesor(id)
);
GO

-- INSCRIPCION A FINAL
CREATE TABLE DROP_DATABASE.Inscripcion_Final (
    InscripcionFinalId BIGINT identity(1,1) PRIMARY KEY,
    legajoAlumno BIGINT NOT NULL,
    fechaInscripcion DATETIME2(6) NOT NULL CONSTRAINT DF_InscripcionFinal_Fecha DEFAULT (SYSDATETIME()),
    finalId BIGINT NOT NULL,
    presente BIT NULL,
    profesor BIGINT NULL,
    CONSTRAINT FK_InscripcionFinal_Alumno FOREIGN KEY (legajoAlumno)
        REFERENCES DROP_DATABASE.Alumno(legajoAlumno),
    CONSTRAINT FK_InscripcionFinal_Final FOREIGN KEY (finalId)
        REFERENCES DROP_DATABASE.Final(Final_Nro),
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
    CONSTRAINT fk_legajoAlumnoFactura FOREIGN KEY (legajoAlumno) REFERENCES DROP_DATABASE.Alumno(legajoAlumno)
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
    CONSTRAINT fk_legajoAlumnoEvaluacionRendida FOREIGN KEY (legajoAlumno) REFERENCES DROP_DATABASE.Alumno(legajoAlumno)
);

CREATE TABLE DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion (
    id INT IDENTITY(1,1) PRIMARY KEY,
    evaluacionId INT NOT NULL REFERENCES DROP_DATABASE.Evaluacion(id),
    modulo INT NOT NULL REFERENCES DROP_DATABASE.Modulo_x_Curso(id)
);
GO

--------------------------------------------------------------
-- TRIGGERS
--------------------------------------------------------------
-- Validar que un alumno no se inscriba a un curso que ya finalizó



-- Validar que el alumno esté inscripto antes de rendir evaluación
CREATE TRIGGER DROP_DATABASE.trg_validarInscripcionEvaluacion
ON DROP_DATABASE.Evaluacion_Rendida
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM DROP_DATABASE.Inscripcion_Curso ic
            JOIN DROP_DATABASE.Evaluacion e ON e.cursoId = ic.codigoCurso
            WHERE ic.legajoAlumno = i.legajoAlumno
            AND e.id = i.evaluacionId
            AND ic.estado = 'aprobada'  -- o el estado que indique inscripción activa
        )
    )
    BEGIN
        RAISERROR('El alumno debe estar inscripto en el curso para rendir evaluación.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Validar consistencia en fechas de facturación
CREATE TRIGGER DROP_DATABASE.trg_validarFechasFactura
ON DROP_DATABASE.Factura
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE fechaVencimiento < fechaEmision)
    BEGIN
        RAISERROR('La fecha de vencimiento no puede ser anterior a la fecha de emisión.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger para actualizar automáticamente el estado de inscripción cuando se complete el curso
CREATE TRIGGER DROP_DATABASE.trg_actualizarEstadoInscripcion
ON DROP_DATABASE.Curso
AFTER UPDATE
AS
BEGIN
    IF UPDATE(fechaFin)
    BEGIN
        UPDATE ic
        SET estado = 'finalizado',
            fechaRespuesta = GETDATE()
        FROM DROP_DATABASE.Inscripcion_Curso ic
        INNER JOIN inserted i ON ic.codigoCurso = i.codigoCurso
        WHERE i.fechaFin <= GETDATE()
        AND ic.estado NOT IN ('finalizado', 'cancelada');
    END
END;
GO

CREATE TRIGGER DROP_DATABASE.trg_validarRangoFechasCurso ON DROP_DATABASE.Curso
FOR INSERT, UPDATE
AS BEGIN
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
AS BEGIN
    SET NOCOUNT ON;
    UPDATE ic
    SET ic.fechaRespuesta = SYSDATETIME()
    FROM DROP_DATABASE.Inscripcion_Curso ic
    INNER JOIN inserted i ON ic.Inscripcion_Numero = i.Inscripcion_Numero
    INNER JOIN deleted d ON i.Inscripcion_Numero = d.Inscripcion_Numero
    WHERE ISNULL(i.estado, '') <> ISNULL(d.estado, '');
END;
GO

CREATE TRIGGER DROP_DATABASE.trg_asignarInstanciaParcial
ON DROP_DATABASE.Evaluacion_Rendida
AFTER INSERT
AS BEGIN
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

---------------------------------------------------
-- INDEXES
---------------------------------------------------
-- Para búsquedas por DNI (muy comunes)
CREATE INDEX IX_Profesor_Dni ON DROP_DATABASE.Profesor(dni);
CREATE INDEX IX_Alumno_Dni ON DROP_DATABASE.Alumno(dni);

-- Para búsquedas por nombre/apellido
CREATE INDEX IX_Profesor_Apellido ON DROP_DATABASE.Profesor(apellido);
CREATE INDEX IX_Alumno_Apellido ON DROP_DATABASE.Alumno(apellido);

-- Para consultas por fecha
CREATE INDEX IX_Curso_Fechas ON DROP_DATABASE.Curso(fechaInicio, fechaFin);
CREATE INDEX IX_Inscripcion_Fecha ON DROP_DATABASE.Inscripcion_Curso(fechaInscripcion);
CREATE INDEX IX_Factura_Fechas ON DROP_DATABASE.Factura(fechaEmision, fechaVencimiento);

-- Para joins frecuentes
CREATE INDEX IX_Localidad_Provincia ON DROP_DATABASE.Localidad(provinciaId);
CREATE INDEX IX_Sede_Institucion ON DROP_DATABASE.Sede(institucionId);
CREATE INDEX IX_Curso_Sede ON DROP_DATABASE.Curso(sedeId);
CREATE INDEX IX_Curso_Profesor ON DROP_DATABASE.Curso(profesorId);
CREATE INDEX IX_Curso_Categoria ON DROP_DATABASE.Curso(categoriaId);

-- Para consultas de negocio
CREATE INDEX IX_Final_Curso_Fecha ON DROP_DATABASE.Final(curso, fecha);
CREATE INDEX IX_Evaluacion_Curso ON DROP_DATABASE.Evaluacion(cursoId);
CREATE INDEX IX_Encuesta_Curso ON DROP_DATABASE.Encuesta(cursoId);
CREATE INDEX IX_TP_Alumno_Fecha ON DROP_DATABASE.TP_Alumno(fechaEvaluacion);


CREATE INDEX IX_Inscripcion_Curso_Alumno ON DROP_DATABASE.Inscripcion_Curso(legajoAlumno);
CREATE INDEX IX_Inscripcion_Curso_Curso ON DROP_DATABASE.Inscripcion_Curso(codigoCurso);
CREATE INDEX IX_TP_Alumno_Curso ON DROP_DATABASE.TP_Alumno(curso);
CREATE INDEX IX_Factura_Alumno ON DROP_DATABASE.Factura(legajoAlumno);
CREATE INDEX IX_Pago_Factura ON DROP_DATABASE.Pago(id);


---------------------------------------------------
-- CONSTRAINTS 
---------------------------------------------------
ALTER TABLE DROP_DATABASE.Curso
ADD CONSTRAINT CK_Curso_PrecioPositivo CHECK (precioMensual >= 0);

-- Validar formato de email
ALTER TABLE DROP_DATABASE.Alumno
ADD CONSTRAINT CK_Alumno_Email_Formato 
CHECK (mail IS NULL OR mail LIKE '%_@_%._%');

ALTER TABLE DROP_DATABASE.Profesor
ADD CONSTRAINT CK_Profesor_Email_Formato 
CHECK (mail IS NULL OR mail LIKE '%_@_%._%');

ALTER TABLE DROP_DATABASE.Sede
ADD CONSTRAINT CK_Sede_Email_Formato 
CHECK (mail IS NULL OR mail LIKE '%_@_%._%');

-- Validar rangos de notas
ALTER TABLE DROP_DATABASE.Evaluacion_Rendida
ADD CONSTRAINT CK_EvaluacionRendida_NotaValida 
CHECK (nota BETWEEN 1 AND 10 OR nota IS NULL); --Tiene que ser null?

ALTER TABLE DROP_DATABASE.TP_Alumno
ADD CONSTRAINT CK_TPAlumno_NotaValida 
CHECK (nota BETWEEN 1 AND 10 OR nota IS NULL); --Tiene que ser null?

ALTER TABLE DROP_DATABASE.Final_rendido
ADD CONSTRAINT CK_FinalRendido_NotaValida CHECK (nota BETWEEN 1 AND 10 OR nota IS NULL); --Tiene que ser null?
GO

-- Validar que las fechas de nacimiento sean razonables
ALTER TABLE DROP_DATABASE.Alumno
ADD CONSTRAINT CK_Alumno_FechaNacimiento 
CHECK (fechaNacimiento <= GETDATE() AND fechaNacimiento > '1900-01-01');

ALTER TABLE DROP_DATABASE.Profesor
ADD CONSTRAINT CK_Profesor_FechaNacimiento 
CHECK (fechaNacimiento <= GETDATE() AND fechaNacimiento > '1900-01-01');

-- ---------------------------------------
-- BLOQUES DE MIGRACIÓN 
-- ---------------------------------------

/* Bloque 1: Instituciones, Turnos, Dia_Semana, Provincias */
BEGIN TRY
    BEGIN TRAN;

    INSERT INTO DROP_DATABASE.Institucion (nombre, razonSocial, cuit)
    SELECT DISTINCT Institucion_Nombre, Institucion_RazonSocial, Institucion_Cuit
    FROM gd_esquema.Maestra
    WHERE Institucion_Nombre IS NOT NULL
      AND Institucion_Nombre NOT IN (SELECT nombre FROM DROP_DATABASE.Institucion);

    INSERT INTO DROP_DATABASE.Turno (nombre)
    SELECT DISTINCT Curso_Turno
    FROM gd_esquema.Maestra
    WHERE Curso_Turno IS NOT NULL
      AND Curso_Turno NOT IN (SELECT nombre FROM DROP_DATABASE.Turno);

    IF NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Dia_Semana WHERE dia = 'Lunes')
    BEGIN
        INSERT INTO DROP_DATABASE.Dia_Semana (dia) VALUES
        ('Lunes'),('Martes'),('Miércoles'),('Jueves'),('Viernes'),('Sábado');
    END

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

    COMMIT TRAN;
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en bloque 1: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 2: Localidades (normalización) */
BEGIN TRY
    BEGIN TRAN;

    ;WITH RawSrc AS (
        SELECT LTRIM(RTRIM(REPLACE(m.Sede_Localidad,';',''))) AS nombre_clean, p.id AS provinciaId
        FROM gd_esquema.Maestra m
        LEFT JOIN DROP_DATABASE.Provincia p
            ON UPPER(LTRIM(RTRIM(REPLACE(p.nombre,';','')))) COLLATE Latin1_General_CI_AI
               = UPPER(LTRIM(RTRIM(REPLACE(m.Sede_Provincia,';','')))) COLLATE Latin1_General_CI_AI
        WHERE m.Sede_Localidad IS NOT NULL

        UNION ALL

        SELECT LTRIM(RTRIM(REPLACE(m.Profesor_Localidad,';',''))), p.id
        FROM gd_esquema.Maestra m
        JOIN DROP_DATABASE.Provincia p
            ON UPPER(LTRIM(RTRIM(REPLACE(p.nombre,';','')))) COLLATE Latin1_General_CI_AI
               = UPPER(LTRIM(RTRIM(REPLACE(m.Profesor_Provincia,';','')))) COLLATE Latin1_General_CI_AI
        WHERE m.Profesor_Localidad IS NOT NULL

        UNION ALL

        SELECT LTRIM(RTRIM(REPLACE(m.Alumno_Localidad,';',''))), p.id
        FROM gd_esquema.Maestra m
        JOIN DROP_DATABASE.Provincia p
            ON UPPER(LTRIM(RTRIM(REPLACE(p.nombre,';','')))) COLLATE Latin1_General_CI_AI
               = UPPER(LTRIM(RTRIM(REPLACE(m.Alumno_Provincia,';','')))) COLLATE Latin1_General_CI_AI
        WHERE m.Alumno_Localidad IS NOT NULL
    ),
    DistinctSrc AS (
        SELECT DISTINCT nombre_clean, provinciaId FROM RawSrc
    ),
    Ranked AS (
        SELECT nombre_clean, provinciaId,
               ROW_NUMBER() OVER (PARTITION BY nombre_clean ORDER BY provinciaId) AS rn
        FROM DistinctSrc
    ),
    ToInsert AS (
        SELECT r.nombre_clean, r.provinciaId
        FROM Ranked r
        LEFT JOIN DROP_DATABASE.Localidad l
            ON r.nombre_clean COLLATE Latin1_General_CI_AI = LTRIM(RTRIM(l.nombre)) COLLATE Latin1_General_CI_AI
        WHERE r.rn = 1 AND l.nombre IS NULL
    )
    INSERT INTO DROP_DATABASE.Localidad (nombre, provinciaId)
    SELECT nombre_clean, provinciaId FROM ToInsert;

    COMMIT TRAN;
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error al insertar localidades: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 3: Sedes y Profesores */
BEGIN TRY
    BEGIN TRAN;

    INSERT INTO DROP_DATABASE.Sede (nombre, telefono, direccion, mail, localidadId, institucionId)
    SELECT DISTINCT m.Sede_Nombre, m.Sede_Telefono, m.Sede_Direccion, m.Sede_Mail, l.id, i.id
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Provincia p ON p.nombre = m.Sede_Provincia
    JOIN DROP_DATABASE.Localidad l ON l.nombre = m.Sede_Localidad AND l.provinciaId = p.id
    JOIN DROP_DATABASE.Institucion i ON i.nombre = m.Institucion_Nombre
    WHERE m.Sede_Nombre IS NOT NULL
      AND m.Sede_Direccion IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM DROP_DATABASE.Sede s2 WHERE s2.nombre = m.Sede_Nombre AND s2.direccion = m.Sede_Direccion
      );

    INSERT INTO DROP_DATABASE.Profesor (localidadId, apellido, nombre, dni, fechaNacimiento, direccion, telefono, mail)
    SELECT DISTINCT l.id, m.Profesor_Apellido, m.Profesor_Nombre, m.Profesor_Dni,
           TRY_CONVERT(datetime2(6), m.Profesor_FechaNacimiento), m.Profesor_Direccion, m.Profesor_Telefono, m.Profesor_Mail
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Provincia p ON p.nombre = m.Profesor_Provincia
    JOIN DROP_DATABASE.Localidad l ON l.nombre = m.Profesor_Localidad AND l.provinciaId = p.id
    WHERE m.Profesor_Apellido IS NOT NULL
      AND m.Profesor_Nombre IS NOT NULL
      AND m.Profesor_Dni IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Profesor pr WHERE pr.dni = m.Profesor_Dni);

    COMMIT TRAN;
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en sedes/profesores: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 4: Categorias y Cursos (preservo Curso_Codigo del origen) */
BEGIN TRY
    BEGIN TRAN;

    INSERT INTO DROP_DATABASE.Categoria(nombre)
    SELECT DISTINCT Curso_Categoria FROM gd_esquema.Maestra
    WHERE Curso_Categoria IS NOT NULL
      AND Curso_Categoria NOT IN (SELECT nombre FROM DROP_DATABASE.Categoria);

    -- Si querés preservar los códigos originales de curso (Curso_Codigo), dejamos IDENTITY_INSERT ON.
    SET IDENTITY_INSERT DROP_DATABASE.Curso ON;

    INSERT INTO DROP_DATABASE.Curso (codigoCurso, sedeId, profesorId, nombre, descripcion, categoriaId, fechaInicio, fechaFin, turnoId, precioMensual)
    SELECT DISTINCT
        m.Curso_Codigo,
        s.id,
        pr.id,
        m.Curso_Nombre,
        m.Curso_Descripcion,
        c.id,
        TRY_CONVERT(datetime2(6), m.Curso_FechaInicio),
        TRY_CONVERT(datetime2(6), m.Curso_FechaFin),
        t.id,
        m.Curso_PrecioMensual
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Sede s ON s.direccion = m.Sede_Direccion AND s.nombre = m.Sede_Nombre
    JOIN DROP_DATABASE.Profesor pr ON pr.apellido = m.Profesor_Apellido AND pr.dni = m.Profesor_Dni
    JOIN DROP_DATABASE.Categoria c ON c.nombre = m.Curso_Categoria
    JOIN DROP_DATABASE.Turno t ON t.nombre = m.Curso_Turno
    WHERE m.Curso_Codigo IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Curso c2 WHERE c2.codigoCurso = m.Curso_Codigo);

    SET IDENTITY_INSERT DROP_DATABASE.Curso OFF;

    COMMIT TRAN;
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en cursos: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 5: Dias, Modulos y Modulo_x_Curso */
BEGIN TRY
    BEGIN TRAN;

    INSERT INTO DROP_DATABASE.Dia_Cursado (diaSemanaId, codigoCurso)
    SELECT DISTINCT ds.id, c.codigoCurso
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Dia_Semana ds ON ds.dia = m.Curso_Dia
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
    WHERE m.Curso_Dia IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Dia_Cursado dc WHERE dc.diaSemanaId = ds.id AND dc.codigoCurso = c.codigoCurso);

    INSERT INTO DROP_DATABASE.Modulo (nombre, descripcion)
    SELECT DISTINCT Modulo_Nombre, Modulo_Descripcion
    FROM gd_esquema.Maestra
    WHERE Modulo_Nombre IS NOT NULL
      AND Modulo_Descripcion IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Modulo mm WHERE mm.nombre = Modulo_Nombre AND mm.descripcion = Modulo_Descripcion);

    INSERT INTO DROP_DATABASE.Modulo_x_Curso (cursoId, moduloId)
    SELECT DISTINCT c.codigoCurso, m.id
    FROM gd_esquema.Maestra ma
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = ma.Curso_Codigo
    JOIN DROP_DATABASE.Modulo m ON ma.Modulo_Nombre = m.nombre AND ma.Modulo_Descripcion = m.descripcion
    WHERE ma.Curso_Codigo IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Modulo_x_Curso mc WHERE mc.cursoId = c.codigoCurso AND mc.moduloId = m.id);

    COMMIT TRAN;
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en dias/modulos: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 6: Alumnos (NORMALIZADO por legajo numérico, PRIORIDAD: DNI) */
BEGIN TRY
    BEGIN TRAN;

    ;WITH Src AS (
        SELECT
            m.*,
            TRY_CAST(LTRIM(RTRIM(m.Alumno_Legajo)) AS BIGINT) AS legajo_num,
            CASE WHEN TRY_CAST(m.Alumno_Dni AS BIGINT) IS NOT NULL THEN 1 ELSE 0 END AS has_dni,
            CASE WHEN m.Alumno_Mail IS NOT NULL AND CHARINDEX('@', m.Alumno_Mail) > 0 THEN 1 ELSE 0 END AS has_mail,
            CASE WHEN TRY_CONVERT(datetime2(6), m.Alumno_FechaNacimiento) IS NOT NULL THEN 1 ELSE 0 END AS has_fecha,
            CASE WHEN m.Curso_Codigo IS NOT NULL THEN 1 ELSE 0 END AS has_curso,
            (
                CASE WHEN m.Alumno_Nombre IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Alumno_Apellido IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Alumno_Dni IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Alumno_Localidad IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Alumno_Direccion IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Alumno_FechaNacimiento IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Alumno_Mail IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Alumno_Telefono IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN m.Curso_Codigo IS NOT NULL THEN 1 ELSE 0 END
            ) AS completeness_score
        FROM gd_esquema.Maestra m
        WHERE m.Alumno_Legajo IS NOT NULL
    ),
    Ranked AS (
        SELECT s.*,
               ROW_NUMBER() OVER (
                   PARTITION BY s.legajo_num
                   ORDER BY
                       s.has_dni DESC, s.has_mail DESC, s.has_fecha DESC, s.has_curso DESC, s.completeness_score DESC,
                       TRY_CONVERT(datetime2(6), s.Alumno_FechaNacimiento) DESC
               ) AS rn
        FROM Src s
        WHERE s.legajo_num IS NOT NULL
    )
    INSERT INTO DROP_DATABASE.Alumno (legajoAlumno, nombre, apellido, dni, localidad_id, domicilio, fechaNacimiento, direccion, mail, telefono)
    SELECT
        r.legajo_num,
        r.Alumno_Nombre,
        r.Alumno_Apellido,
        CASE WHEN TRY_CAST(r.Alumno_Dni AS BIGINT) IS NOT NULL THEN TRY_CAST(r.Alumno_Dni AS INT) ELSE NULL END,
        (SELECT TOP 1 id FROM DROP_DATABASE.Localidad WHERE LTRIM(RTRIM(nombre)) COLLATE Latin1_General_CI_AI = LTRIM(RTRIM(r.Alumno_Localidad)) COLLATE Latin1_General_CI_AI),
        r.Alumno_Direccion,
        TRY_CONVERT(datetime2(6), r.Alumno_FechaNacimiento),
        r.Alumno_Direccion,
        r.Alumno_Mail,
        r.Alumno_Telefono
    FROM Ranked r
    WHERE r.rn = 1
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Alumno a WHERE a.legajoAlumno = r.legajo_num);

    COMMIT TRAN;
    PRINT 'Insert Alumnos OK';
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en insert alumnos: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 7: TP_Alumno, Inscripcion_Curso, Final, Final_rendido, Inscripcion_Final
   Correcciones principales:
   - No forzamos IDENTITY_INSERT en Inscripcion_Curso (dejamos que la DB asigne IDs)
   - Final: insertamos sin tocar identity (Final.Final_Nro será generado)
   - Final_rendido y Inscripcion_Final: insertamos sin tocar las columnas identity
*/
BEGIN TRY
    BEGIN TRAN;

    -- TP_Alumno
    INSERT INTO DROP_DATABASE.TP_Alumno (legajoAlumno, nota, fechaEvaluacion, curso)
    SELECT DISTINCT a.legajoAlumno, m.Trabajo_Practico_Nota, TRY_CONVERT(datetime2(6), m.Trabajo_Practico_FechaEvaluacion), c.codigoCurso
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = TRY_CAST(LTRIM(RTRIM(m.Alumno_Legajo)) AS BIGINT)
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
    WHERE m.Trabajo_Practico_FechaEvaluacion IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM DROP_DATABASE.TP_Alumno tpa
          WHERE tpa.legajoAlumno = a.legajoAlumno AND tpa.fechaEvaluacion = TRY_CONVERT(datetime2(6), m.Trabajo_Practico_FechaEvaluacion) AND tpa.curso = c.codigoCurso
      );

    -- Inscripcion_Curso (dejamos que DB genere Inscripcion_Numero)
    INSERT INTO DROP_DATABASE.Inscripcion_Curso (fechaInscripcion, legajoAlumno, codigoCurso, estado, fechaRespuesta)
    SELECT DISTINCT
        TRY_CONVERT(datetime2(6), m.Inscripcion_Fecha),
        a.legajoAlumno,
        c.codigoCurso,
        m.Inscripcion_Estado,
        TRY_CONVERT(datetime2(6), m.Inscripcion_FechaRespuesta)
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = TRY_CAST(LTRIM(RTRIM(m.Alumno_Legajo)) AS BIGINT)
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
    WHERE m.Inscripcion_Estado IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM DROP_DATABASE.Inscripcion_Curso ic
          WHERE ic.legajoAlumno = a.legajoAlumno AND ic.codigoCurso = c.codigoCurso
                AND ic.fechaInscripcion = TRY_CONVERT(datetime2(6), m.Inscripcion_Fecha)
      );

    -- Final: insertamos eventos finales únicos por fecha/hora/curso
    INSERT INTO DROP_DATABASE.Final (fecha, hora, curso, descripcion)
    SELECT DISTINCT TRY_CONVERT(datetime2(6), m.Examen_Final_Fecha) AS fecha,
           m.Examen_Final_Hora AS hora,
           c.codigoCurso AS curso,
           m.Examen_Final_Descripcion AS descripcion
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
    WHERE m.Examen_Final_Fecha IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Final f WHERE f.fecha = TRY_CONVERT(datetime2(6), m.Examen_Final_Fecha) AND ISNULL(f.hora,'') = ISNULL(m.Examen_Final_Hora,'') AND f.curso = c.codigoCurso);

    -- Final_rendido: solo si existe alumno y final (match por fecha+hora+curso)
    INSERT INTO DROP_DATABASE.Final_rendido (legajoAlumno, finalId, presente, nota, profesor)
    SELECT DISTINCT a.legajoAlumno, f.Final_Nro, m.Evaluacion_Final_Presente, m.Evaluacion_Final_Nota, p.id AS profesor
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = TRY_CAST(LTRIM(RTRIM(m.Alumno_Legajo)) AS BIGINT)
    JOIN DROP_DATABASE.Final f ON f.fecha = TRY_CONVERT(datetime2(6), m.Examen_Final_Fecha) AND ISNULL(f.hora,'') = ISNULL(m.Examen_Final_Hora,'') AND f.curso = m.Curso_Codigo
    LEFT JOIN DROP_DATABASE.Profesor p ON p.dni = m.Profesor_Dni
    WHERE m.Examen_Final_Fecha IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Final_rendido fr WHERE fr.legajoAlumno = a.legajoAlumno AND fr.finalId = f.Final_Nro);

    -- Inscripcion_Final: solo si existe alumno y final (no forzamos identity)
    INSERT INTO DROP_DATABASE.Inscripcion_Final (legajoAlumno, fechaInscripcion, finalId, presente, profesor)
    SELECT DISTINCT a.legajoAlumno, TRY_CONVERT(datetime2(6), m.Inscripcion_Final_Fecha), f.Final_Nro, m.Evaluacion_Final_Presente, p.id AS profesor
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = TRY_CAST(LTRIM(RTRIM(m.Alumno_Legajo)) AS BIGINT)
    JOIN DROP_DATABASE.Final f ON f.Final_Nro = m.Inscripcion_Final_Nro
    LEFT JOIN DROP_DATABASE.Profesor p ON p.dni = m.Profesor_Dni
    WHERE m.Inscripcion_Final_Nro IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Inscripcion_Final inf WHERE inf.legajoAlumno = a.legajoAlumno AND inf.finalId = f.Final_Nro);

    COMMIT TRAN;
    PRINT 'Bloque finales/inscripciones OK';
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en bloque finales/inscripciones: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 8: Encuestas y detalles */
BEGIN TRY
    BEGIN TRAN;

    INSERT INTO DROP_DATABASE.Encuesta (cursoId)
    SELECT DISTINCT c.codigoCurso
    FROM gd_esquema.Maestra ma
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = ma.Curso_Codigo
    WHERE (ma.Encuesta_Pregunta1 IS NOT NULL AND LTRIM(RTRIM(ma.Encuesta_Pregunta1)) <> '')
       OR (ma.Encuesta_Pregunta2 IS NOT NULL AND LTRIM(RTRIM(ma.Encuesta_Pregunta2)) <> '')
       OR (ma.Encuesta_Pregunta3 IS NOT NULL AND LTRIM(RTRIM(ma.Encuesta_Pregunta3)) <> '')
       OR (ma.Encuesta_Pregunta4 IS NOT NULL AND LTRIM(RTRIM(ma.Encuesta_Pregunta4)) <> '')
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Encuesta e WHERE e.cursoId = c.codigoCurso);

    DECLARE @n INT = 1;
    WHILE @n <= 4
    BEGIN
        INSERT INTO DROP_DATABASE.Pregunta (pregunta, nroPregunta, encuestaId)
        SELECT DISTINCT
            CASE @n WHEN 1 THEN m.Encuesta_Pregunta1 WHEN 2 THEN m.Encuesta_Pregunta2 WHEN 3 THEN m.Encuesta_Pregunta3 WHEN 4 THEN m.Encuesta_Pregunta4 END,
            @n,
            e.encuestaId
        FROM gd_esquema.Maestra m
        JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
        JOIN DROP_DATABASE.Encuesta e ON e.cursoId = c.codigoCurso
        WHERE (CASE @n WHEN 1 THEN m.Encuesta_Pregunta1 WHEN 2 THEN m.Encuesta_Pregunta2 WHEN 3 THEN m.Encuesta_Pregunta3 WHEN 4 THEN m.Encuesta_Pregunta4 END) IS NOT NULL
          AND LTRIM(RTRIM((CASE @n WHEN 1 THEN m.Encuesta_Pregunta1 WHEN 2 THEN m.Encuesta_Pregunta2 WHEN 3 THEN m.Encuesta_Pregunta3 WHEN 4 THEN m.Encuesta_Pregunta4 END))) <> ''
          AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Pregunta p WHERE p.encuestaId = e.encuestaId AND p.nroPregunta = @n);

        SET @n = @n + 1;
    END

    INSERT INTO DROP_DATABASE.Encuesta_Respondida (fechaRegistro, encuestaObservacion, encuestaId)
    SELECT DISTINCT TRY_CONVERT(datetime2(6), m.Encuesta_FechaRegistro), m.Encuesta_Observacion, e.encuestaId
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
    JOIN DROP_DATABASE.Encuesta e ON e.cursoId = c.codigoCurso
    WHERE m.Encuesta_FechaRegistro IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Encuesta_Respondida er WHERE er.encuestaId = e.encuestaId AND er.fechaRegistro = TRY_CONVERT(datetime2(6), m.Encuesta_FechaRegistro));

    DECLARE @m INT = 1;
    WHILE @m <= 4
    BEGIN
        INSERT INTO DROP_DATABASE.Detalle_Encuesta_Respondida (preguntaId, respuestaNota, encuestaRespondidaId)
        SELECT DISTINCT p.id, 
            CASE @m WHEN 1 THEN m.Encuesta_Nota1 WHEN 2 THEN m.Encuesta_Nota2 WHEN 3 THEN m.Encuesta_Nota3 WHEN 4 THEN m.Encuesta_Nota4 END,
            er.id
        FROM gd_esquema.Maestra m
        JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
        JOIN DROP_DATABASE.Encuesta e ON e.cursoId = c.codigoCurso
        JOIN DROP_DATABASE.Encuesta_Respondida er ON er.encuestaId = e.encuestaId AND er.fechaRegistro = TRY_CONVERT(datetime2(6), m.Encuesta_FechaRegistro)
        JOIN DROP_DATABASE.Pregunta p ON p.encuestaId = e.encuestaId AND p.nroPregunta = @m
        WHERE (CASE @m WHEN 1 THEN m.Encuesta_Nota1 WHEN 2 THEN m.Encuesta_Nota2 WHEN 3 THEN m.Encuesta_Nota3 WHEN 4 THEN m.Encuesta_Nota4 END) IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Detalle_Encuesta_Respondida der WHERE der.preguntaId = p.id AND der.encuestaRespondidaId = er.id);

        SET @m = @m + 1;
    END

    COMMIT TRAN;
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en bloque encuestas: ' + ERROR_MESSAGE();
END CATCH;
GO

/* Bloque 9: Pagos, Facturas, Periodos, Detalle_Factura, Evaluaciones y Evaluacion_Rendida (respetando trigger) */
BEGIN TRY
    BEGIN TRAN;

    INSERT INTO DROP_DATABASE.Medio_Pago (medioPago)
    SELECT DISTINCT Pago_MedioPago FROM gd_esquema.Maestra
    WHERE Pago_MedioPago IS NOT NULL
      AND Pago_MedioPago NOT IN (SELECT medioPago FROM DROP_DATABASE.Medio_Pago);

    INSERT INTO DROP_DATABASE.Factura (facturaNumero, fechaEmision, fechaVencimiento, importeTotal, legajoAlumno)
    SELECT DISTINCT TRY_CAST(f.Factura_Numero AS BIGINT), TRY_CONVERT(datetime2(6), f.Factura_FechaEmision), TRY_CONVERT(datetime2(6), f.Factura_FechaVencimiento), f.Factura_Total, a.legajoAlumno
    FROM gd_esquema.Maestra f
    JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = TRY_CAST(LTRIM(RTRIM(f.Alumno_Legajo)) AS BIGINT)
    WHERE f.Factura_Numero IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Factura fa WHERE fa.facturaNumero = TRY_CAST(f.Factura_Numero AS BIGINT));

    INSERT INTO DROP_DATABASE.Pago (fecha, importe, medioPagoId, facturaNumero)
    SELECT DISTINCT TRY_CONVERT(datetime2(6), m.Pago_Fecha), m.Pago_Importe, mp.id, f.facturaNumero
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Medio_Pago mp ON mp.medioPago = m.Pago_MedioPago
    JOIN DROP_DATABASE.Factura f ON f.facturaNumero = TRY_CAST(m.Factura_Numero AS BIGINT)
    WHERE m.Pago_Fecha IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Pago p WHERE p.facturaNumero = f.facturaNumero AND p.importe = m.Pago_Importe AND p.fecha = TRY_CONVERT(datetime2(6), m.Pago_Fecha));

    INSERT INTO DROP_DATABASE.Periodo (periodoAnio, periodoMes)
    SELECT DISTINCT Periodo_Anio, Periodo_Mes FROM gd_esquema.Maestra
    WHERE Periodo_Anio IS NOT NULL AND Periodo_Mes IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Periodo per WHERE per.periodoAnio = gd_esquema.Maestra.Periodo_Anio AND per.periodoMes = gd_esquema.Maestra.Periodo_Mes);

    INSERT INTO DROP_DATABASE.Detalle_Factura (codigoCurso, importe, facturaNumero, periodoId)
    SELECT DISTINCT c.codigoCurso, m.Detalle_Factura_Importe, f.facturaNumero, p.id
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = m.Curso_Codigo
    JOIN DROP_DATABASE.Factura f ON f.facturaNumero = TRY_CAST(m.Factura_Numero AS BIGINT)
    JOIN DROP_DATABASE.Periodo p ON p.periodoAnio = m.Periodo_Anio AND p.periodoMes = m.Periodo_Mes
    WHERE m.Detalle_Factura_Importe IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Detalle_Factura df WHERE df.facturaNumero = f.facturaNumero AND df.codigoCurso = c.codigoCurso);

    INSERT INTO DROP_DATABASE.Evaluacion (fecha, cursoId)
    SELECT DISTINCT TRY_CONVERT(datetime2(6), Evaluacion_Curso_fechaEvaluacion), Curso_Codigo
    FROM gd_esquema.Maestra
    WHERE Evaluacion_Curso_fechaEvaluacion IS NOT NULL
      AND EXISTS (SELECT 1 FROM DROP_DATABASE.Curso c WHERE c.codigoCurso = gd_esquema.Maestra.Curso_Codigo)
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Evaluacion e WHERE e.fecha = TRY_CONVERT(datetime2(6), gd_esquema.Maestra.Evaluacion_Curso_fechaEvaluacion) AND e.cursoId = gd_esquema.Maestra.Curso_Codigo);

    -- Evaluacion_Rendida: solo si el alumno tiene inscripcion aprobada en el curso de la evaluacion
    INSERT INTO DROP_DATABASE.Evaluacion_Rendida (legajoAlumno, nota, presente, instancia, evaluacionId)
    SELECT DISTINCT a.legajoAlumno, m.Evaluacion_Curso_Nota, m.Evaluacion_Curso_Presente, m.Evaluacion_Curso_Instancia, e.id
    FROM gd_esquema.Maestra m
    JOIN DROP_DATABASE.Alumno a ON a.legajoAlumno = TRY_CAST(LTRIM(RTRIM(m.Alumno_Legajo)) AS BIGINT)
    JOIN DROP_DATABASE.Evaluacion e ON e.fecha = TRY_CONVERT(datetime2(6), m.Evaluacion_Curso_fechaEvaluacion)
    JOIN DROP_DATABASE.Inscripcion_Curso ic ON ic.legajoAlumno = a.legajoAlumno AND ic.codigoCurso = e.cursoId AND ISNULL(ic.estado,'') = 'aprobada'
    WHERE m.Evaluacion_Curso_fechaEvaluacion IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Evaluacion_Rendida er WHERE er.legajoAlumno = a.legajoAlumno AND er.evaluacionId = e.id);

    INSERT INTO DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion (evaluacionId, modulo)
    SELECT DISTINCT e.id, mxc.id
    FROM gd_esquema.Maestra ma
    JOIN DROP_DATABASE.Evaluacion e ON e.fecha = TRY_CONVERT(datetime2(6), ma.Evaluacion_Curso_fechaEvaluacion)
    JOIN DROP_DATABASE.Modulo m ON m.nombre = ma.Modulo_Nombre
    JOIN DROP_DATABASE.Curso c ON c.codigoCurso = ma.Curso_Codigo
    JOIN DROP_DATABASE.Modulo_x_Curso mxc ON mxc.moduloId = m.id AND mxc.cursoId = c.codigoCurso
    WHERE ma.Evaluacion_Curso_fechaEvaluacion IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion mx WHERE mx.evaluacionId = e.id AND mx.modulo = mxc.id);

    COMMIT TRAN;
    PRINT 'Bloque pagos/evaluaciones OK';
END TRY
BEGIN CATCH
    ROLLBACK TRAN;
    PRINT 'Error en bloque pagos/evaluaciones: ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT 'MIGRACIÓN COMPLETA (version corregida)';
GO



CREATE TRIGGER DROP_DATABASE.trg_validarCursoActivoInscripcion
ON DROP_DATABASE.Inscripcion_Curso
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN DROP_DATABASE.Curso c ON c.codigoCurso = i.codigoCurso
        WHERE c.fechaFin < GETDATE()
    )
    BEGIN
        RAISERROR('No se puede inscribir a un curso que ya finalizó.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
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
