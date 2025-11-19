use GD2C2025;
GO

CREATE VIEW DROP_DATABASE.vw_inscripciones AS
SELECT
    YEAR(i.fechaInscripcion) AS anio,
    MONTH(i.fechaInscripcion) AS mes,
    s.id as sedeId,
    cat.id as categoriaId,
    cu.turnoId as turnoId,
    COUNT(*) AS cant_inscripciones,
    SUM(CASE WHEN i.estado = 'Aprobada' THEN 1 ELSE 0 END) AS cant_aprobadas,
    SUM(CASE WHEN i.estado = 'Rechazada' THEN 1 ELSE 0 END) AS cant_rechazadas
FROM DROP_DATABASE.Inscripcion_Curso i
    JOIN DROP_DATABASE.Curso cu ON cu.codigoCurso = i.codigoCurso
    JOIN DROP_DATABASE.Sede s ON s.id = cu.sedeId
    JOIN DROP_DATABASE.Categoria cat ON cat.id = cu.categoriaId
GROUP BY
    YEAR(i.fechaInscripcion),
    MONTH(i.fechaInscripcion),
    s.id,
    cat.id,
    cu.turnoId;
GO


CREATE VIEW DROP_DATABASE.vw_cursada AS
with alumnos_curso as (
    SELECT
        cu.codigoCurso,
        er.legajoAlumno,
        MIN(er.nota) AS notaMinima,
        tp.nota AS notaTP,
        CASE WHEN MIN(er.nota) >= 4 and tp.nota >= 4 THEN 1 ELSE 0 END AS aprobado,
        CASE WHEN MIN(er.nota) is NULL or MIN(er.nota) < 4 or tp.nota < 4 THEN 1 ELSE 0 END AS desaprobado
    FROM DROP_DATABASE.Curso cu 
    JOIN DROP_DATABASE.Modulo_x_Curso mxc 
        ON cu.codigoCurso = mxc.cursoId
    JOIN DROP_DATABASE.Modulo_de_curso_tomado_en_evaluacion mce 
        ON mxc.moduloId = mce.modulo
    JOIN DROP_DATABASE.Evaluacion e 
        ON mce.evaluacionId = e.id
    JOIN DROP_DATABASE.Evaluacion_Rendida er 
        ON er.evaluacionId = e.id
    JOIN DROP_DATABASE.TP_Alumno tp on tp.legajoAlumno=er.legajoAlumno and tp.curso=cu.codigoCurso
    GROUP BY 
        cu.codigoCurso,
        er.legajoAlumno,
        tp.nota
    )
SELECT
    YEAR(cu.fechaInicio) AS anio,
    MONTH(cu.fechaInicio) AS mes,
    cu.sedeId,
    cu.categoriaId,
    SUM(ac.aprobado) AS cant_aprobados,
    SUM(ac.desaprobado) AS cant_desaprobados
FROM alumnos_curso ac
JOIN DROP_DATABASE.Curso cu 
    ON cu.codigoCurso = ac.codigoCurso
GROUP BY
    YEAR(cu.fechaInicio),
    MONTH(cu.fechaInicio),
    cu.sedeId,
    cu.categoriaId;

GO


CREATE VIEW DROP_DATABASE.vw_finales AS
SELECT 
    YEAR(cu.fechaInicio) AS anio,
    MONTH(cu.fechaInicio) AS mes,
    cu.sedeId,
    cu.categoriaId,

    -- Rango etario del alumno
    CASE 
        WHEN DATEDIFF(year, a.fechaNacimiento, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(year, a.fechaNacimiento, GETDATE()) BETWEEN 25 AND 35 THEN '25-35'
        WHEN DATEDIFF(year, a.fechaNacimiento, GETDATE()) BETWEEN 36 AND 50 THEN '35-50'
        ELSE '>50'
    END AS rangoAlumno,

    -- Rango etario del profesor
    CASE 
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 25 AND 35 THEN '25-35'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 36 AND 50 THEN '35-50'
        ELSE '>50'
    END AS rangoProfesor,

    SUM(CASE WHEN fr.presente = 1 THEN 1 ELSE 0 END) AS cant_presentes,
    SUM(CASE WHEN fr.presente = 0 or fr.presente IS NULL THEN 1 ELSE 0 END) AS cant_ausentes,
    AVG(fr.nota) AS notaPromedio

FROM DROP_DATABASE.Final f
JOIN DROP_DATABASE.Final_rendido fr 
    ON f.Final_Nro = fr.finalId
JOIN DROP_DATABASE.Curso cu 
    ON cu.codigoCurso = f.curso
JOIN DROP_DATABASE.Alumno a 
    ON a.legajoAlumno = fr.legajoAlumno 
JOIN DROP_DATABASE.Profesor p
    ON p.id = cu.profesorId   

GROUP BY
    YEAR(cu.fechaInicio),
    MONTH(cu.fechaInicio),
    cu.sedeId,
    cu.categoriaId,
    CASE 
        WHEN DATEDIFF(year, a.fechaNacimiento, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(year, a.fechaNacimiento, GETDATE()) BETWEEN 25 AND 35 THEN '25-35'
        WHEN DATEDIFF(year, a.fechaNacimiento, GETDATE()) BETWEEN 36 AND 50 THEN '35-50'
        ELSE '>50'
    END,
    CASE 
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 25 AND 35 THEN '25-35'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 36 AND 50 THEN '35-50'
        ELSE '>50'
    END;
GO


CREATE VIEW DROP_DATABASE.vw_pagos AS
SELECT
    YEAR(p.fecha) AS anio,
    MONTH(p.fecha) AS mes,
    p.medioPagoId,          
    SUM(p.importe) AS montoPagado,
    SUM(
        CASE 
            WHEN p.fecha > f.fechaVencimiento THEN p.importe 
            ELSE 0 
        END
    ) AS montoFueraTermino

FROM DROP_DATABASE.Pago p
JOIN DROP_DATABASE.Factura f 
    ON p.facturaNumero = f.facturaNumero
JOIN DROP_DATABASE.Medio_Pago mp 
    ON p.medioPagoId = mp.id

GROUP BY
    YEAR(p.fecha),
    MONTH(p.fecha),
    p.medioPagoId;
GO


CREATE VIEW DROP_DATABASE.vw_facturacion AS
SELECT
    YEAR(fact.fechaEmision) AS anio,
    MONTH(fact.fechaEmision) AS mes,
    cu.sedeId,
    cu.categoriaId,

    SUM(fact.importeTotal) AS importeTotal,

    SUM(
        CASE 
            WHEN p.facturaNumero IS NULL THEN fact.importeTotal
            ELSE 0
        END
    ) AS importeAdeudado

FROM DROP_DATABASE.Factura fact
JOIN DROP_DATABASE.Detalle_Factura df 
    ON fact.facturaNumero = df.facturaNumero
JOIN DROP_DATABASE.Curso cu 
    ON df.codigoCurso = cu.codigoCurso

LEFT JOIN DROP_DATABASE.Pago p 
    ON p.facturaNumero = fact.facturaNumero

GROUP BY
    YEAR(fact.fechaEmision),
    MONTH(fact.fechaEmision),
    cu.sedeId,
    cu.categoriaId;

GO



CREATE VIEW DROP_DATABASE.vw_encuestas AS
SELECT DISTINCT
    YEAR(cu.fechaInicio) AS anio,
    MONTH(cu.fechaInicio) AS mes,
    cu.sedeId,
    cu.categoriaId,

    -- Rango etario del profesor
    CASE 
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 25 AND 35 THEN '25-35'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 36 AND 50 THEN '35-50'
        ELSE '>50'
    END AS rangoProfesor,

    -- Bloque de satisfacción
    CASE
        WHEN der.respuestaNota BETWEEN 4 AND 5 THEN 'Satisfecho'
        WHEN der.respuestaNota = 3 THEN 'Neutral'
        ELSE 'Insatisfecho'
    END AS bloqueSatisfaccion,

    -- Métricas BI
    SUM(CASE WHEN der.respuestaNota BETWEEN 4 AND 5 THEN 1 ELSE 0 END) AS cant_satisfechos,
    SUM(CASE WHEN der.respuestaNota = 3 THEN 1 ELSE 0 END) AS cant_neutrales,
    SUM(CASE WHEN der.respuestaNota BETWEEN 1 AND 2 THEN 1 ELSE 0 END) AS cant_insatisfechos

FROM DROP_DATABASE.Encuesta_Respondida er
JOIN DROP_DATABASE.Encuesta e
    ON er.encuestaId = e.encuestaId
JOIN DROP_DATABASE.Curso cu
    ON e.cursoId = cu.codigoCurso
JOIN DROP_DATABASE.Profesor p
    ON cu.profesorId = p.id
JOIN DROP_DATABASE.Detalle_Encuesta_Respondida der ON der.encuestaRespondidaId=e.encuestaId 

GROUP BY
    YEAR(cu.fechaInicio),
    MONTH(cu.fechaInicio),
    cu.sedeId,
    cu.categoriaId,

    CASE 
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) < 25 THEN '<25'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 25 AND 35 THEN '25-35'
        WHEN DATEDIFF(year, p.fechaNacimiento, GETDATE()) BETWEEN 36 AND 50 THEN '35-50'
        ELSE '>50'
    END,

    CASE
        WHEN der.respuestaNota BETWEEN 4 AND 5 THEN 'Satisfecho'
        WHEN der.respuestaNota = 3 THEN 'Neutral'
        ELSE 'Insatisfecho'
    END;

GO

CREATE TABLE DROP_DATABASE.BI_DIM_RANGO_ETARIO_PROFESOR (
    idRangoAlumno INT PRIMARY KEY,
    descripcion VARCHAR(255)
);

CREATE TABLE DROP_DATABASE.BI_DIM_RANGO_ETARIO_ALUMNO (
    idRangoAlumno INT PRIMARY KEY,
    descripcion VARCHAR(255)
);

CREATE TABLE DROP_DATABASE.BI_DIM_TIEMPO (
    idTiempo INT PRIMARY KEY,
    anio INT,
    mes TINYINT,
    cuatrimestre TINYINT,
    semestre TINYINT
);

CREATE TABLE DROP_DATABASE.BI_DIM_TURNO (
    idTurno INT PRIMARY KEY,
    turno VARCHAR(255)
);

CREATE TABLE DROP_DATABASE.BI_DIM_MEDIO_PAGO (
    idMedioPago INT PRIMARY KEY,
    nombre VARCHAR(255)
);

CREATE TABLE DROP_DATABASE.BI_DIM_BLOQUE_SATISFACCION (
    idBloque INT PRIMARY KEY,
    descripcion VARCHAR(255)
);

CREATE TABLE DROP_DATABASE.BI_DIM_SEDE (
    idSede INT PRIMARY KEY,
    nombre NVARCHAR(255)
);

CREATE TABLE DROP_DATABASE.BI_DIM_CATEGORIA (
    idCategoria INT PRIMARY KEY,
    categoria VARCHAR(255)
);


CREATE TABLE DROP_DATABASE.BI_FACT_FACTURACION (
    id_tiempo INT,
    id_sede INT,
    id_categoria INT,
    importe_total FLOAT NULL,
    importe_adeudado FLOAT NULL,
    CONSTRAINT PK_FACT_FACTURACION PRIMARY KEY (id_tiempo, id_sede, id_categoria),
    CONSTRAINT FK_FACT_FAC_TIEMPO FOREIGN KEY (id_tiempo)
        REFERENCES DROP_DATABASE.BI_DIM_TIEMPO(idTiempo),
    CONSTRAINT FK_FACT_FAC_SEDE FOREIGN KEY (id_sede)
        REFERENCES DROP_DATABASE.BI_DIM_SEDE(idSede),
    CONSTRAINT FK_FACT_FAC_CATEGORIA FOREIGN KEY (id_categoria)
        REFERENCES DROP_DATABASE.BI_DIM_CATEGORIA(idCategoria)
);

CREATE TABLE DROP_DATABASE.BI_FACT_PAGOS (
    id_tiempo INT,
    id_medio_pago INT,
    monto_pagado FLOAT NULL,
    monto_fuera_termino FLOAT NULL,
    CONSTRAINT PK_FACT_PAGOS PRIMARY KEY (id_tiempo, id_medio_pago),
    CONSTRAINT FK_PAGOS_TIEMPO FOREIGN KEY (id_tiempo)
        REFERENCES DROP_DATABASE.BI_DIM_TIEMPO(idTiempo),
    CONSTRAINT FK_PAGOS_MEDIO FOREIGN KEY (id_medio_pago)
        REFERENCES DROP_DATABASE.BI_DIM_MEDIO_PAGO(idMedioPago)
);

CREATE TABLE DROP_DATABASE.BI_FACT_ENCUESTAS (
    id_tiempo INT,
    id_sede INT,
    id_categoria INT,
    id_rango_profesor INT,
    id_bloque INT,
    cant_satisfechos INT NULL,
    cant_neutrales INT NULL,
    cant_insatisfechos INT NULL,
    CONSTRAINT PK_FACT_ENCUESTAS PRIMARY KEY
        (id_tiempo, id_sede, id_categoria, id_rango_profesor, id_bloque),
    CONSTRAINT FK_ENC_TIEMPO FOREIGN KEY (id_tiempo)
        REFERENCES DROP_DATABASE.BI_DIM_TIEMPO(idTiempo),
    CONSTRAINT FK_ENC_SEDE FOREIGN KEY (id_sede)
        REFERENCES DROP_DATABASE.BI_DIM_SEDE(idSede),
    CONSTRAINT FK_ENC_CATEGORIA FOREIGN KEY (id_categoria)
        REFERENCES DROP_DATABASE.BI_DIM_CATEGORIA(idCategoria),
    CONSTRAINT FK_ENC_RANGO_PROF FOREIGN KEY (id_rango_profesor)
        REFERENCES DROP_DATABASE.BI_DIM_RANGO_ETARIO_PROFESOR(idRangoAlumno),
    CONSTRAINT FK_ENC_BLOQUE FOREIGN KEY (id_bloque)
        REFERENCES DROP_DATABASE.BI_DIM_BLOQUE_SATISFACCION(idBloque)
);

CREATE TABLE DROP_DATABASE.BI_FACT_CURSADA (
    id_tiempo INT,
    id_sede INT,
    id_categoria INT,
    cant_aprobados INT NULL,
    cant_desaprobados INT NULL,
    CONSTRAINT PK_FACT_CURSADA PRIMARY KEY (id_tiempo, id_sede, id_categoria),
    CONSTRAINT FK_CURS_TIEMPO FOREIGN KEY (id_tiempo)
        REFERENCES DROP_DATABASE.BI_DIM_TIEMPO(idTiempo),
    CONSTRAINT FK_CURS_SEDE FOREIGN KEY (id_sede)
        REFERENCES DROP_DATABASE.BI_DIM_SEDE(idSede),
    CONSTRAINT FK_CURS_CATEGORIA FOREIGN KEY (id_categoria)
        REFERENCES DROP_DATABASE.BI_DIM_CATEGORIA(idCategoria)
);

CREATE TABLE DROP_DATABASE.BI_FACT_INSCRIPCIONES (
    id_tiempo INT,
    id_sede INT,
    id_categoria INT,
    id_turno INT,
    cant_inscripciones INT NULL,
    cant_rechazos INT NULL,
    cant_aprobadas INT NULL,
    CONSTRAINT PK_FACT_INSCRIPCIONES PRIMARY KEY
        (id_tiempo, id_sede, id_categoria, id_turno),
    CONSTRAINT FK_INS_TIEMPO FOREIGN KEY (id_tiempo)
        REFERENCES DROP_DATABASE.BI_DIM_TIEMPO(idTiempo),
    CONSTRAINT FK_INS_SEDE FOREIGN KEY (id_sede)
        REFERENCES DROP_DATABASE.BI_DIM_SEDE(idSede),
    CONSTRAINT FK_INS_CATEGORIA FOREIGN KEY (id_categoria)
        REFERENCES DROP_DATABASE.BI_DIM_CATEGORIA(idCategoria),
    CONSTRAINT FK_INS_TURNO FOREIGN KEY (id_turno)
        REFERENCES DROP_DATABASE.BI_DIM_TURNO(idTurno)
);

CREATE TABLE DROP_DATABASE.BI_FACT_FINALES (
    id_tiempo INT,
    id_sede INT,
    id_categoria INT,
    id_rango_profesor INT,
    id_rango_alumno INT,
    cant_presentes FLOAT NULL,
    cant_ausentes FLOAT NULL,
    nota_promedio INT NULL,
    CONSTRAINT PK_FACT_FINALES PRIMARY KEY
        (id_tiempo, id_sede, id_categoria, id_rango_profesor, id_rango_alumno),
    CONSTRAINT FK_FIN_TIEMPO FOREIGN KEY (id_tiempo)
        REFERENCES DROP_DATABASE.BI_DIM_TIEMPO(idTiempo),
    CONSTRAINT FK_FIN_SEDE FOREIGN KEY (id_sede)
        REFERENCES DROP_DATABASE.BI_DIM_SEDE(idSede),
    CONSTRAINT FK_FIN_CATEGORIA FOREIGN KEY (id_categoria)
        REFERENCES DROP_DATABASE.BI_DIM_CATEGORIA(idCategoria),
    CONSTRAINT FK_FIN_RANGO_PROF FOREIGN KEY (id_rango_profesor)
        REFERENCES DROP_DATABASE.BI_DIM_RANGO_ETARIO_PROFESOR(idRangoAlumno),
    CONSTRAINT FK_FIN_RANGO_ALUM FOREIGN KEY (id_rango_alumno)
        REFERENCES DROP_DATABASE.BI_DIM_RANGO_ETARIO_ALUMNO(idRangoAlumno)
);
