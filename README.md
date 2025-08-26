# Moodle 5.0 Docker Setup

Un setup completo de Docker para Moodle 5.0 con MariaDB, Redis y configuración optimizada para producción.

## 🚀 Características

- **Moodle 5.0 Stable** - Última versión estable
- **PHP 8.2** con todas las extensiones requeridas
- **MariaDB 10.11** como base de datos
- **Redis** para caché y sesiones
- **Apache 2.4** con configuración optimizada
- **SSL/TLS ready** (configuración incluida)
- **Health checks** integrados
- **Multi-stage build** para optimización de tamaño
- **Configuración por variables de entorno**

## 📋 Requisitos Previos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Al menos 2GB de RAM disponible
- Espacio en disco: ~1GB para imágenes base + datos

## 🛠 Instalación Rápida

1. **Clona o descarga los archivos**
   ```bash
   git clone <tu-repositorio>
   cd moodle-docker
   ```

2. **Configura las variables de entorno**
   ```bash
   cp .env-example .env
   # Edita .env con tus configuraciones
   ```

3. **Ejecuta con Docker Compose**
   ```bash
   docker-compose up -d
   ```

4. **Accede a Moodle**
   - URL: http://localhost:8080
   - Usuario admin: `admin`
   - Contraseña: `Admin123!` (cambiar en .env)

## 🔧 Configuración

### Variables de Entorno Principales

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `MOODLE_RELEASE` | Versión de Moodle (branch Git) | `MOODLE_500_STABLE` |
| `MOODLE_URL` | URL base de Moodle | `http://localhost:8080` |
| `DB_PASSWORD` | Contraseña de la base de datos | `moodle_secure_password_2024` |
| `MOODLE_ADMIN_PASSWORD` | Contraseña del administrador | `Admin123!` |
| `PHP_MEMORY_LIMIT` | Límite de memoria PHP | `256M` |
| `TZ` | Zona horaria | `America/Santiago` |

### Estructura de Volúmenes

```
volumes/
├── moodle_data/     # Datos de Moodle (moodledata)
├── moodle_html/     # Código fuente de Moodle
├── db_data/         # Base de datos MariaDB
└── redis_data/      # Cache Redis
```

## 🌐 Servicios Incluidos

### Moodle Web (Puerto 8080)
- PHP 8.2 + Apache 2.4
- Todas las extensiones PHP necesarias
- Configuración optimizada para Moodle

### Base de Datos (Puerto 3306)
- MariaDB 10.11
- Configuración optimizada para Moodle
- Charset UTF8MB4 por defecto

### Cache Redis (Puerto 6379)
- Redis 7 Alpine
- Configurado para sesiones y cache
- Política de memoria optimizada

### phpMyAdmin (Puerto 8081) - Opcional
- Interfaz web para administrar la base de datos
- Acceso con credenciales de root
- Activar con: `docker-compose --profile tools up -d`

## 🚀 Uso Avanzado

### Desarrollo Local
```bash
# Para desarrollo con debug activado
echo "MOODLE_DEBUG=true" >> .env
docker-compose up -d
```

### Producción
```bash
# Configuraciones de producción recomendadas
export MOODLE_URL="https://tu-dominio.com"
export PHP_MEMORY_LIMIT="512M"
export MOODLE_DEBUG="false"
docker-compose up -d
```

### SSL/HTTPS
1. Coloca tus certificados en `./ssl/`
2. Modifica `apache-config.conf` para incluir configuración SSL
3. Actualiza `MOODLE_URL` con https://

### Backup

**Backup de la base de datos:**
```bash
docker-compose exec db mysqldump -u root -p moodle > backup_$(date +%Y%m%d_%H%M%S).sql
```

**Backup completo:**
```bash
docker-compose exec moodle tar -czf /tmp/moodledata_backup.tar.gz /var/www/moodledata
docker cp moodle_web:/tmp/moodledata_backup.tar.gz ./backups/
```

### Actualización

1. **Backup completo** de datos y base de datos
2. **Cambiar la versión** en `.env`:
   ```bash
   MOODLE_RELEASE=MOODLE_501_STABLE  # Nueva versión
   ```
3. **Reconstruir** la imagen:
   ```bash
   docker-compose build --no-cache moodle
   docker-compose up -d
   ```

## 📊 Monitoreo y Logs

### Ver logs en tiempo real
```bash
# Todos los servicios
docker-compose logs -f

# Solo Moodle
docker-compose logs -f moodle

# Solo base de datos
docker-compose logs -f db
```

### Health Checks
```bash
# Verificar estado de los contenedores
docker-compose ps

# Verificar health check específico
docker inspect moodle_web | grep -A 10 Health
```

### Métricas de rendimiento
```bash
# Uso de recursos
docker stats

# Espacio usado por volúmenes
docker system df -v
```

## 🔧 Personalización

### Agregar Extensiones PHP Adicionales
Edita el `Dockerfile` y agrega las extensiones necesarias:
```dockerfile
RUN install-php-extensions \
    extensión1 \
    extensión2
```

### Configur
