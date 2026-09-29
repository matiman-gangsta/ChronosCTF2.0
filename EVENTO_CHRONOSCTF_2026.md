# 🛡️ ChronosCTF 2026: Torneo Universitario de Ciberseguridad
### Documento Descriptivo y Ficha Técnica del Evento (1-2 Planas)

---

## 📌 1. Resumen Ejecutivo y Ficha Técnica

| Parámetro | Detalle |
| :--- | :--- |
| **Nombre Oficial** | ChronosCTF 2026 |
| **Formato de Competencia** | Modo Jeopardy (Resolución de retos por categorías y niveles) |
| **Modalidad** | En línea / Plataforma Web Centralizada |
| **Público Objetivo** | Estudiantes universitarios de ingeniería, informática y entusiastas de la ciberseguridad |
| **Plataforma Central** | GZCTF (Plataforma moderna en .NET + Vue con orquestación nativa de contenedores) |
| **Formato de Banderas** | `CHRONOS{cadena_alfanumerica_secreta}` (con banderas dinámicas por equipo) |
| **Infraestructura Cloud** | Microsoft Azure (Aprovisionamiento automatizado con Terraform) |

---

## 🎯 2. Objetivos del Evento

1. **Desarrollo de Habilidades Prácticas:** Poner a prueba y perfeccionar destrezas en auditoría técnica, hacking ético, análisis forense e investigación digital en un entorno seguro, legal y controlado.
2. **Resolución de Problemas y Trabajo en Equipo:** Incentivar el pensamiento crítico lateral, la formulación de hipótesis y la colaboración bajo presión temporal.
3. **Formación Universitaria Aplicada:** Cerrar la brecha entre la teoría académica y los vectores de ataque contemporáneos que enfrentan las organizaciones en la vida real.

---

## 🧩 3. Categorías y Áreas de Desafíos

La competencia incluye retos balanceados desde nivel introductorio (*Easy*) hasta nivel intermedio-avanzado (*Hard*), distribuidos en las siguientes especialidades:

* **🌐 Explotación Web (Web Exploitation):**
  Auditoría sobre aplicaciones y APIs web vulnerables. Los participantes descubren y explotan fallos comunes del estándar OWASP Top 10, tales como inyecciones SQL (*SQLi*), inyección de comandos en el sistema operativo (*Command Injection*) con evasión de filtros/WAF, salto de directorios (*Local File Inclusion / Directory Traversal*) y secuestro de rutas (*Path Hijacking*).
* **🔍 Análisis Forense Digital (Digital Forensics & Stego):**
  Inspección y recuperación de evidencias en artefactos digitales. Involucra análisis de metadatos EXIF en archivos multimedia, esteganografía, extracción de cadenas imprimibles y reconstrucción de información oculta o alterada.
* **🕵️ Inteligencia de Fuentes Abiertas (OSINT & Git Forensics):**
  Técnicas de recolección de información pública, análisis de historiales de repositorios de control de versiones (commits borrados, fugas de credenciales en Git) y rastreo de huella digital corporativa.
* **⚙️ Criptografía, Ingeniería Inversa y Explotación de Binarios (Crypto / Rev / Pwn):**
  Cifrados débiles, análisis de código compilado, desobfuscación y control de flujo en binarios de sistema.

---

## 🏗️ 4. Infraestructura Tecnológica y Seguridad Operacional

El torneo opera sobre una arquitectura moderna, escalable y aislada para garantizar alta disponibilidad y juego limpio:

* **Despliegue como Código (IaC):** Toda la infraestructura en la nube está definida con **Terraform**, permitiendo levantar o destruir el entorno de manera reproducible en minutos.
* **Instancias Dinámicas por Equipo (Orquestación GZCTF):** Cada equipo interactúa con una instancia de contenedor privada y temporal. GZCTF inyecta una bandera dinámica única en cada contenedor, impidiendo que un equipo comparta su flag con otro y erradicando el riesgo de que un jugador interfiera o sabotee el entorno de sus competidores.
* **Aislamiento Contenedorizado (Docker Hardening):** Los contenedores ejecutan usuarios sin privilegios (`USER ctf` no-root), capacidades del kernel reducidas (`cap_drop: ALL`) y límites de recursos estrictos (*cgroups*: memoria y CPU) para resguardar la salud del host.
* **Integración y Despliegue Continuo (CI/CD):** Pipelines en GitHub Actions con autenticación segura por tokens **OIDC** hacia Azure, validando automáticamente la seguridad de cada reto y planificando los cambios de infraestructura.

---

## 💰 5. Sustentabilidad y Eficiencia Operacional (FinOps)

La plataforma fue diseñada bajo estrictos principios de optimización de costos (**FinOps**), garantizando que el torneo opere íntegramente dentro del crédito educativo de **$100 USD (Azure for Students)**:

* **Cómputo:** Una única máquina virtual burstable (`Standard_B2s` con 2 vCPU y 4 GB RAM) sobre Ubuntu 24.04 LTS.
* **Bases de Datos Locales:** En lugar de costosas bases de datos gestionadas PaaS, GZCTF corre con una instancia local containerizada de PostgreSQL 16 con almacenamiento persistente.
* **Registro de Imágenes:** Azure Container Registry (ACR) en modalidad *Basic*.
* **Presupuesto Proyectado:** **~$43.20 USD / mes** durante el ciclo de pruebas y el fin de semana del torneo, manteniendo un margen seguro superior al 55% del crédito total.

---

## 🏆 6. Dinámica de la Competencia y Puntuación

1. **Acceso al Tablero:** Cada equipo se registra en la plataforma web oficial mediante credenciales únicas.
2. **Descubrimiento de Retos:** Los desafíos están disponibles simultáneamente. Los participantes seleccionan los retos, analizan el código/archivo descargable o interactúan con la instancia web en vivo.
3. **Captura de Banderas (Flags):** Al vulnerar con éxito el objetivo, el equipo obtiene una bandera única con el formato `CHRONOS{...}` que se envía a la plataforma para acreditar los puntos.
4. **Tablero en Tiempo Real (Scoreboard):** CTFd actualiza en vivo el puntaje global, mostrando gráficas de progresión temporal y reconociendo al primer equipo en resolver cada reto (*First Blood*).
5. **Cierre y Premiación:** Al finalizar el tiempo reglamentario, el marcador se congela y se proclaman los equipos ganadores con base en el puntaje total y desempate por tiempo de entrega.
