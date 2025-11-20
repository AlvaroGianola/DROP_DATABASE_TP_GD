use GD2C2025;
GO

CREATE VIEW DROP_DATABASE.vw_inscripciones AS
SELECT
    YEAR(COALESCE(i.fechaInscripcion, '19000101')) AS anio,
    MONTH(COALESCE(i.fechaInscripcion, '19000101')) AS mes,
    COALESCE(s.id, 0) as sedeId,
    COALESCE(cat.id, 0) as categoriaId,
    COALESCE(cu.turnoId, 0) as turnoId,
    COUNT(*) AS cant_inscripciones,
    SUM(CASE WHEN COALESCE(i.estado, '') = 'Confirmada' THEN 1 ELSE 0 END) AS cant_confirmadas,
    SUM(CASE WHEN COALESCE(i.estado, '') = 'Rechazada' THEN 1 ELSE 0 END) AS cant_rechazadas
FROM DROP_DATABASE.Inscripcion_Curso i
    JOIN DROP_DATABASE.Curso cu ON cu.codigoCurso = i.codigoCurso
    JOIN DROP_DATABASE.Sede s ON s.id = cu.sedeId
    JOIN DROP_DATABASE.Categoria cat ON cat.id = cu.categoriaId
WHERE i.fechaInscripcion IS NOT NULL AND i.estado IS NOT NULL
GROUP BY
    YEAR(COALESCE(i.fechaInscripcion, '19000101')),
    MONTH(COALESCE(i.fechaInscripcion, '19000101')),
    COALESCE(s.id, 0),
    COALESCE(cat.id, 0),
    COALESCE(cu.turnoId, 0);
GO


CREATE VIEW DROP_DATABASE.vw_cursada AS
with alumnos_curso as (
    SELECT
        cu.codigoCurso,
        er.legajoAlumno,
        MIN(COALESCE(er.nota, 0)) AS notaMinima,
        COALESCE(tp.nota, 0) AS notaTP,
        CASE WHEN MIN(COALESCE(er.nota,0)) >= 4 
              AND COALESCE(tp.nota,0) >= 4
             THEN 1 ELSE 0 END AS aprobado,

        CASE WHEN MIN(COALESCE(er.nota,0)) < 4
               OR COALESCE(tp.nota,0) < 4
             THEN 1 ELSE 0 END AS desaprobado
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
    AVG(COALESCE(fr.nota, 0)) AS notaPromedio

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
    SUM(COALESCE(p.importe, 0)) AS montoPagado,

    SUM(
        CASE 
            WHEN p.fecha > f.fechaVencimiento THEN COALESCE(p.importe,0)
            ELSE 0 
        END
    ) AS montoFueraTermino



FROM DROP_DATABASE.Pago p
JOIN DROP_DATABASE.Factura f 
    ON p.facturaNumero = f.facturaNumero
JOIN DROP_DATABASE.Medio_Pago mp 
    ON p.medioPagoId = mp.id
WHERE (p.fecha IS NOT NULL)
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

    SUM(COALESCE(fact.importeTotal, 0)) AS importeTotal,

    SUM(
        CASE 
            WHEN p.facturaNumero IS NULL THEN COALESCE(fact.importeTotal, 0)
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
WHERE fact.fechaEmision IS NOT NULL
GROUP BY
    YEAR(fact.fechaEmision),
    MONTH(fact.fechaEmision),
    cu.sedeId,
    cu.categoriaId;

GO



CREATE VIEW DROP_DATABASE.vw_encuestas AS
SELECT
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

    -- Cantidades según el enunciado
    SUM(CASE WHEN der.respuestaNota BETWEEN 7 AND 10 THEN 1 ELSE 0 END) AS cant_satisfechos,
    SUM(CASE WHEN der.respuestaNota BETWEEN 5 AND 6 THEN 1 ELSE 0 END) AS cant_neutrales,
    SUM(CASE WHEN der.respuestaNota BETWEEN 1 AND 4 THEN 1 ELSE 0 END) AS cant_insatisfechos,

    -- Índice de satisfacción
    -- ((%satisfechos - %insatisfechos) + 100)/2
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE ((((SUM(CASE WHEN der.respuestaNota BETWEEN 7 AND 10 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))-(SUM(CASE WHEN der.respuestaNota BETWEEN 1 AND 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))) + 100) / 2)
    END AS indice_satisfaccion

FROM DROP_DATABASE.Encuesta_Respondida er
JOIN DROP_DATABASE.Encuesta e
    ON er.encuestaId = e.encuestaId
JOIN DROP_DATABASE.Curso cu
    ON e.cursoId = cu.codigoCurso
JOIN DROP_DATABASE.Profesor p
    ON cu.profesorId = p.id
JOIN DROP_DATABASE.Detalle_Encuesta_Respondida der
    ON der.encuestaRespondidaId = er.id

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
    cant_satisfechos INT NULL,
    cant_neutrales INT NULL,
    cant_insatisfechos INT NULL,
    indice_satisfaccion FLOAT NOT NULL,
    CONSTRAINT PK_FACT_ENCUESTAS PRIMARY KEY
        (id_tiempo, id_sede, id_categoria, id_rango_profesor),
    CONSTRAINT FK_ENC_TIEMPO FOREIGN KEY (id_tiempo)
        REFERENCES DROP_DATABASE.BI_DIM_TIEMPO(idTiempo),
    CONSTRAINT FK_ENC_SEDE FOREIGN KEY (id_sede)
        REFERENCES DROP_DATABASE.BI_DIM_SEDE(idSede),
    CONSTRAINT FK_ENC_CATEGORIA FOREIGN KEY (id_categoria)
        REFERENCES DROP_DATABASE.BI_DIM_CATEGORIA(idCategoria),
    CONSTRAINT FK_ENC_RANGO_PROF FOREIGN KEY (id_rango_profesor)
        REFERENCES DROP_DATABASE.BI_DIM_RANGO_ETARIO_PROFESOR(idRangoAlumno),

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

GO

INSERT INTO DROP_DATABASE.BI_DIM_TIEMPO (idTiempo, anio, mes, cuatrimestre, semestre)
SELECT DISTINCT
    anio * 100 + mes AS idTiempo,
    anio,
    mes,
    CASE 
        WHEN mes BETWEEN 1 AND 4 THEN 1
        WHEN mes BETWEEN 5 AND 8 THEN 2
        ELSE 3
    END AS cuatrimestre,
    CASE 
        WHEN mes BETWEEN 1 AND 6 THEN 1
        ELSE 2
    END AS semestre
FROM (
    SELECT anio, mes FROM DROP_DATABASE.vw_inscripciones
    UNION SELECT anio, mes FROM DROP_DATABASE.vw_cursada
    UNION SELECT anio, mes FROM DROP_DATABASE.vw_finales
    UNION SELECT anio, mes FROM DROP_DATABASE.vw_pagos
    UNION SELECT anio, mes FROM DROP_DATABASE.vw_facturacion
    UNION SELECT anio, mes FROM DROP_DATABASE.vw_encuestas
) t;

INSERT INTO DROP_DATABASE.BI_DIM_SEDE (idSede, nombre)
SELECT DISTINCT
    s.id,
    s.nombre
FROM DROP_DATABASE.Sede s;


INSERT INTO DROP_DATABASE.BI_DIM_CATEGORIA (idCategoria, categoria)
SELECT DISTINCT
    c.id,
    c.nombre
FROM DROP_DATABASE.Categoria c;

INSERT INTO DROP_DATABASE.BI_DIM_TURNO (idTurno, turno)
SELECT DISTINCT
    t.id,
    t.nombre
FROM DROP_DATABASE.Turno t;

INSERT INTO DROP_DATABASE.BI_DIM_MEDIO_PAGO (idMedioPago, nombre)
SELECT DISTINCT
    mp.id,
    mp.medioPago
FROM DROP_DATABASE.Medio_Pago mp;

--INSERT INTO DROP_DATABASE.BI_DIM_BLOQUE_SATISFACCION (idBloque, descripcion)
--VALUES
--(1, 'Satisfecho'),
--(2, 'Neutral'),
--(3, 'Insatisfecho');

INSERT INTO DROP_DATABASE.BI_DIM_RANGO_ETARIO_PROFESOR (idRangoAlumno, descripcion)
VALUES
(1, '<25'),
(2, '25-35'),
(3, '35-50'),
(4, '>50');

INSERT INTO DROP_DATABASE.BI_DIM_RANGO_ETARIO_ALUMNO (idRangoAlumno, descripcion)
VALUES
(1, '<25'),
(2, '25-35'),
(3, '35-50'),
(4, '>50');


INSERT INTO DROP_DATABASE.BI_FACT_INSCRIPCIONES
(id_tiempo, id_sede, id_categoria, id_turno, cant_inscripciones, cant_rechazos, cant_aprobadas)
SELECT
    anio * 100 + mes AS id_tiempo,
    sedeId,
    categoriaId,
    turnoId,
    cant_inscripciones,
    cant_rechazadas,
    cant_confirmadas
FROM DROP_DATABASE.vw_inscripciones --VER (523 filas afectadas) Warning: Null value is eliminated by an aggregate or other SET operation.
WHERE anio IS NOT NULL AND mes IS NOT NULL;

INSERT INTO DROP_DATABASE.BI_FACT_CURSADA
(id_tiempo, id_sede, id_categoria, cant_aprobados, cant_desaprobados)
SELECT
    anio * 100 + mes,
    sedeId,
    categoriaId,
    cant_aprobados,
    cant_desaprobados
FROM DROP_DATABASE.vw_cursada;

INSERT INTO DROP_DATABASE.BI_FACT_FINALES 
(id_tiempo, id_sede, id_categoria, id_rango_profesor, id_rango_alumno, 
 cant_presentes, cant_ausentes, nota_promedio)
SELECT
    anio * 100 + mes,
    sedeId,
    categoriaId,

    CASE rangoProfesor
        WHEN '<25' THEN 1
        WHEN '25-35' THEN 2
        WHEN '35-50' THEN 3
        ELSE 4
    END,

    CASE rangoAlumno
        WHEN '<25' THEN 1
        WHEN '25-35' THEN 2
        WHEN '35-50' THEN 3
        ELSE 4
    END,

    cant_presentes,
    cant_ausentes,
    notaPromedio
FROM DROP_DATABASE.vw_finales;


INSERT INTO DROP_DATABASE.BI_FACT_PAGOS
(id_tiempo, id_medio_pago, monto_pagado, monto_fuera_termino)
SELECT
    anio * 100 + mes,
    medioPagoId,
    montoPagado,
    montoFueraTermino
FROM DROP_DATABASE.vw_pagos;

INSERT INTO DROP_DATABASE.BI_FACT_FACTURACION --(964 filas afectadas) Warning: Null value is eliminated by an aggregate or other SET operation.
(id_tiempo, id_sede, id_categoria, importe_total, importe_adeudado)
SELECT
    anio * 100 + mes,
    sedeId,
    categoriaId,
    importeTotal,
    importeAdeudado
FROM DROP_DATABASE.vw_facturacion
WHERE anio IS NOT NULL AND mes IS NOT NULL;

INSERT INTO DROP_DATABASE.BI_FACT_ENCUESTAS
(id_tiempo, id_sede, id_categoria, id_rango_profesor, 
 cant_satisfechos, cant_neutrales, cant_insatisfechos, indice_satisfaccion)
SELECT
    anio * 100 + mes,
    sedeId,
    categoriaId,

    CASE rangoProfesor
        WHEN '<25'   THEN 1
        WHEN '25-35' THEN 2
        WHEN '35-50' THEN 3
        ELSE 4
    END,

    cant_satisfechos,
    cant_neutrales,
    cant_insatisfechos,
    indice_satisfaccion
FROM DROP_DATABASE.vw_encuestas;

GO
CREATE VIEW DROP_DATABASE.categorias_y_turnos_mas_solicitados AS
SELECT TOP 3
    t.anio,
    s.nombre AS sede,
    c.categoria,
    tu.turno,
    f.cant_inscripciones
FROM DROP_DATABASE.BI_FACT_INSCRIPCIONES f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_SEDE s ON f.id_sede = s.idSede
JOIN DROP_DATABASE.BI_DIM_CATEGORIA c ON f.id_categoria = c.idCategoria
JOIN DROP_DATABASE.BI_DIM_TURNO tu ON f.id_turno = tu.idTurno
ORDER BY f.cant_inscripciones DESC;

GO
CREATE VIEW DROP_DATABASE.tasa_rechazo_inscripciones AS
SELECT
    t.anio,
    t.mes,
    s.nombre AS sede,
    SUM(f.cant_rechazos) * 1.0 / SUM(f.cant_inscripciones) AS tasa_rechazo
FROM DROP_DATABASE.BI_FACT_INSCRIPCIONES f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_SEDE s ON f.id_sede = s.idSede
GROUP BY t.anio, t.mes, s.nombre;

GO

CREATE VIEW DROP_DATABASE.comparación_desempeño_cursada_por_sede AS
SELECT
    t.anio,
    s.nombre AS sede,
    SUM(f.cant_aprobados) * 1.0 /
    (SUM(f.cant_aprobados) + SUM(f.cant_desaprobados)) AS porcentaje_aprobacion
FROM DROP_DATABASE.BI_FACT_CURSADA f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_SEDE s ON f.id_sede = s.idSede
GROUP BY t.anio, s.nombre;

GO

CREATE VIEW DROP_DATABASE.tiempo_promedio_finalización_curso AS
SELECT
    YEAR(cu.fechaInicio) AS anio,
    c.nombre AS categoria,
    AVG(DATEDIFF(day, cu.fechaInicio, f.fecha)) AS tiempo_promedio_dias
FROM DROP_DATABASE.Curso cu
JOIN DROP_DATABASE.Final f ON f.curso = cu.codigoCurso
JOIN DROP_DATABASE.Final_rendido fr ON fr.finalId = f.Final_Nro
JOIN DROP_DATABASE.Categoria c ON c.id = cu.categoriaId
WHERE fr.nota >= 4  -- finales aprobados
GROUP BY YEAR(cu.fechaInicio), c.nombre;

GO

CREATE VIEW DROP_DATABASE.nota_promedio_finales AS
SELECT
    t.anio,
    t.semestre,
    c.categoria,
    ra.descripcion AS rango_alumno,
    AVG(f.nota_promedio) AS nota_promedio_final
FROM DROP_DATABASE.BI_FACT_FINALES f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_CATEGORIA c ON f.id_categoria = c.idCategoria
JOIN DROP_DATABASE.BI_DIM_RANGO_ETARIO_ALUMNO ra ON ra.idRangoAlumno = f.id_rango_alumno
GROUP BY t.anio, t.semestre, c.categoria, ra.descripcion;

GO

CREATE VIEW DROP_DATABASE.tasa_ausentismo_finales AS
SELECT
    t.anio,
    t.semestre,
    s.nombre AS sede,
    SUM(f.cant_ausentes) * 1.0 /
    (SUM(f.cant_presentes) + SUM(f.cant_ausentes)) AS tasa_ausentismo
FROM DROP_DATABASE.BI_FACT_FINALES f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_SEDE s ON f.id_sede = s.idSede
GROUP BY t.anio, t.semestre, s.nombre;

GO

CREATE VIEW DROP_DATABASE.desvio_pagos AS
SELECT
    t.anio,
    t.semestre,
    mp.nombre AS medio_pago,
    SUM(f.monto_fuera_termino) * 1.0 /
    SUM(f.monto_pagado) AS porcentaje_fuera_termino
FROM DROP_DATABASE.BI_FACT_PAGOS f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_MEDIO_PAGO mp ON f.id_medio_pago = mp.idMedioPago
GROUP BY t.anio, t.semestre, mp.nombre;

GO

CREATE VIEW DROP_DATABASE.tasa_morosidad_financiera_mensual AS
SELECT
    t.anio,
    t.mes,
    s.nombre AS sede,
    c.categoria,
    SUM(f.importe_adeudado) * 1.0 / SUM(f.importe_total) AS tasa_morosidad
FROM DROP_DATABASE.BI_FACT_FACTURACION f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_SEDE s ON f.id_sede = s.idSede
JOIN DROP_DATABASE.BI_DIM_CATEGORIA c ON f.id_categoria = c.idCategoria
GROUP BY t.anio, t.mes, s.nombre, c.categoria;

GO

CREATE VIEW DROP_DATABASE.ingresos_por_categoria_cursos AS
SELECT TOP 3
    t.anio,
    s.nombre AS sede,
    c.categoria,
    SUM(f.importe_total) AS ingresos
FROM DROP_DATABASE.BI_FACT_FACTURACION f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_SEDE s ON f.id_sede = s.idSede
JOIN DROP_DATABASE.BI_DIM_CATEGORIA c ON f.id_categoria = c.idCategoria
GROUP BY t.anio, s.nombre, c.categoria
ORDER BY ingresos DESC;


GO
CREATE VIEW DROP_DATABASE.indice_satisfación AS
SELECT
    t.anio,
    s.nombre AS sede,
    rp.descripcion AS rango_profesor,
    AVG(f.indice_satisfaccion) AS indice_promedio
FROM DROP_DATABASE.BI_FACT_ENCUESTAS f
JOIN DROP_DATABASE.BI_DIM_TIEMPO t ON f.id_tiempo = t.idTiempo
JOIN DROP_DATABASE.BI_DIM_SEDE s ON f.id_sede = s.idSede
JOIN DROP_DATABASE.BI_DIM_RANGO_ETARIO_PROFESOR rp
    ON f.id_rango_profesor = rp.idRangoAlumno
GROUP BY t.anio, s.nombre, rp.descripcion;
