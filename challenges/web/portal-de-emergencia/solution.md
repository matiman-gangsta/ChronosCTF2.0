# 📋 Writeup Oficial: Portal de Emergencia

| Campo | Detalle |
| :--- | :--- |
| **Categoría** | Web / Reconocimiento Básico |
| **Dificultad** | Baby / Introducción |
| **Puntos** | 100 |
| **Flag** | `CHRONOS{h1dd3n_c0mm3nts_4nd_r0b0ts_txt_9182}` |

---

## 1. Resumen del Desafío

El reto presenta una aplicación web corporativa construida en Python (Flask) simulando el portal de respuesta a incidentes de CyberCorp. El objetivo es identificar vectores elementales de fuga de información en etapa de reconocimiento: comentarios residuales dejados por desarrolladores en el código fuente HTML y directivas de exclusión de rastreadores web en `/robots.txt`.

---

## 2. Análisis de Vulnerabilidades

1. **Comentarios HTML expuestos en producción**:
   Al inspeccionar el código fuente (`Ctrl + U` o `View Page Source`) de la página raíz (`/`), se aprecian comentarios HTML destinados a los ingenieros de soporte:
   ```html
   <!-- NOTA DE SEGURIDAD / CONSEJO PARA EL EQUIPO DE INFRAESTRUCTURA: -->
   <!-- En caso de contingencia mayor, recuerden que las rutas de backup -->
   <!-- y diagnóstico administrativo fueron restringidas en el estándar -->
   <!-- de rastreadores web. Consultar: /robots.txt -->
   <!-- Parametro opcional de depuración soportado: ?debug=true -->
   ```

2. **Fuga de rutas no públicas vía `/robots.txt`**:
   Los archivos `robots.txt` informan a los bots indexadores (Google, Bing) qué directorios no deben indexar. Sin embargo, no ofrecen protección de acceso. Cualquier usuario puede leer su contenido públicamente.

---

## 3. Pasos de Explotación

### Paso 1: Reconocimiento del archivo robots.txt
Navegar hacia la ruta estándar de robots:
```bash
curl -s http://localhost:8000/robots.txt
```

Respuesta obtenida:
```text
User-agent: *
Disallow: /super-secret-admin-backup-panel
```

### Paso 2: Acceso a la ruta restringida
Acceder mediante navegador o cURL a la ruta descubierta:
```bash
curl -s http://localhost:8000/super-secret-admin-backup-panel
```

O abriendo en el navegador:
`http://localhost:8000/super-secret-admin-backup-panel`

### Paso 3: Recuperación de la Bandera
La página web renderiza la consola administrativa revelando la bandera:
```text
CHRONOS{h1dd3n_c0mm3nts_4nd_r0b0ts_txt_9182}
```

---

## 4. Mitigación y Buenas Prácticas

1. **Eliminar comentarios en entornos productivos**: Utilizar minificadores o pipelines de CI/CD que remuevan comentarios de desarrollo antes del despliegue.
2. **No depender de `robots.txt` para seguridad (Security through Obscurity)**: Cualquier endpoint sensible debe requerir autenticación robusta y control de acceso basado en roles (RBAC), independientemente de si está listado en robots o no.
