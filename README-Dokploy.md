# Moodle 5.0 con Dokploy

Guía completa para desplegar Moodle 5.0 en Dokploy usando Docker Compose con SSL automático, dominio personalizado y gestión simplificada.

## 🚀 ¿Por qué Dokploy?

Dokploy es perfecto para Moodle porque ofrece:

- **SSL automático** con Let's Encrypt
- **Proxy reverso** integrado (Traefik)
- **Interfaz web** para gestión
- **Monitoreo** y logs centralizados
- **Backups** automatizados
- **Multi-servidor** support
- **Volúmenes persistentes** garantizados

## 📋 Prerrequisitos

1. **Servidor con Dokploy instalado**
   ```bash
   curl -sSL https://dokploy.com/install.sh | sh
   ```

2. **Dominio configurado** apuntando a tu servidor
   ```
   A record: moodle.tu-dominio.com → IP_DEL_SERVIDOR
   A record: db.tu-dominio.com → IP_DEL_SERVIDOR (opcional para phpMyAdmin)
   ```

3. **Puertos abiertos**
   - 80 (HTTP - redirige a HTTPS)
   - 443 (HTTPS)
   - 3000 (Dokploy UI)

## 🛠 Instalación en Dokploy

### Paso 1: Crear Proyecto en Dokploy

1. Accede a tu panel de Dokploy: `https://tu-servidor:3000`
2. Crea un nuevo **Proyecto**: `moodle-platform`
3. Dentro del proyecto, crea un **Servicio Compose**

### Paso 2: Configurar el Repositorio

**Opción A: Usando Git**
1. Sube tu código a GitHub/GitLab con estos archivos
2. En Dokploy, configura:
   - **Provider**: GitHub/Git
   - **Repository**: tu-usuario/moodle-dokploy
   - **Branch**: main
   - **Compose Path**: `./docker-compose-dokploy.yml`

**Opción B: Upload directo**
1. Sube los archivos directamente via la interfaz de Dokploy
2. Configura el path del compose

### Paso 3: Variables de Entorno

En la sección **Environment** de Dokploy, agrega:

```env
MOODLE_DOMAIN=moodle.tu-dominio.com
MOODLE_RELEASE=MOODLE_500_STABLE
DB_NAME=moodle
DB_USER=moodle
DB_PASSWORD=tu_password_seguro_2024
MYSQL_ROOT_PASSWORD=root_password_seguro_2024
MOODLE_URL=https://moodle.tu-dominio.com
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASSWORD=Admin123!
MOODLE_ADMIN_EMAIL=admin@tu-dominio.com
MOODLE_FULL_NAME=Mi Plataforma Moodle
MOODLE_SHORT_NAME=MiMoodle
PHP_MEMORY_LIMIT=512M
TZ=America/Santiago
```

### Paso 4: Deploy

1. Haz clic en **Deploy**
2. Dokploy automáticamente:
   - Construirá las imágenes
   - Configurará los volúmenes en `../files/`
   - Configurará Traefik con SSL
   - Iniciará todos los servicios

## 📁 Estructura de Archivos en Dokploy

Dokploy organiza los archivos de esta manera:

```
/etc/dokploy/projects/moodle-platform/compose_ID/
├── docker-compose-dokploy.yml
├── Dockerfile
├── apache-config.conf
├── php.ini
├── docker-entrypoint.sh
└── files/                    # Volúmenes persistentes
    ├── moodledata/           # Datos de Moodle
    ├── moodle-html/          # Código de Moodle
    ├── mariadb-data/         # Base de datos
    └── redis-data/           # Cache Redis
```

## 🌐 Accesos

Una vez desplegado:

- **Moodle**: `https://moodle.tu-dominio.com`
- **phpMyAdmin**: `https://db.moodle.tu-dominio.com` 
- **Dokploy Panel**: `https://tu-servidor:3000`

## 🔧 Gestión con Dokploy

### Monitoreo
- **Logs en tiempo real** desde la interfaz
- **Métricas de CPU/RAM** por contenedor
- **Estado de servicios** visual

### Backups
```bash
# Desde la interfaz de Dokploy o CLI
dokploy backup create --project=moodle-platform
```

### Actualizaciones
1. Cambia `MOODLE_RELEASE` en las variables de entorno
2. Haz **Re-deploy** desde la interfaz
3. Dokploy preservará automáticamente los datos

### Logs y Debugging
- Accede a logs de cada servicio desde la interfaz
- Terminal integrado para cada contenedor
- Restart servicios individuales

## 📊 Escalado y Producción

### Optimizaciones para Producción

1. **Recursos aumentados**:
   ```env
   PHP_MEMORY_LIMIT=1024M
   PHP_MAX_EXECUTION_TIME=600
   PHP_UPLOAD_MAX_FILESIZE=500M
   ```

2. **Base de datos optimizada** (modificar en docker-compose):
   ```yaml
   command: >
     --innodb_buffer_pool_size=1G
     --innodb_log_file_size=128M
     --query_cache_size=128M
   ```

### Multi-servidor con Dokploy

Dokploy permite desplegar en múltiples servidores:

1. **Servidor web**: Moodle + Redis
2. **Servidor DB**: MariaDB dedicado
3. **Servidor files**: NFS para volúmenes compartidos

## 🔒 Seguridad

### Configuraciones Automáticas de Dokploy

- **SSL/TLS**: Let's Encrypt automático
- **Firewall**: Solo puertos necesarios
- **Headers de seguridad**: Via Traefik
- **Network isolation**: Red privada entre contenedores

### Configuraciones Adicionales

1. **WAF** (Web Application Firewall):
   ```yaml
   labels:
     - "traefik.http.middlewares.moodle-waf.plugin.crowdsec-bouncer.enabled=true"
   ```

2. **Rate limiting**:
   ```yaml
   labels:
     - "traefik.http.middlewares.moodle-ratelimit.ratelimit.burst=100"
   ```

## 🚨 Troubleshooting

### Problemas Comunes

1. **Volúmenes no persisten**
   - Verificar que usen `../files/` path
   - Chequear permisos en Dokploy

2. **SSL no funciona**
   - Verificar DNS apunta al servidor
   - Verificar puerto 80/443 abiertos
   - Chequear logs de Traefik en Dokploy

3. **Base de datos no conecta**
   - Verificar variables de entorno
   - Chequear logs del servicio db
   - Verificar red dokploy-network

### Comandos Útiles

```bash
# Ver servicios activos
dokploy ps --project=moodle-platform

# Ver logs específicos
dokploy logs --service=moodle --follow

# Restart servicio
dokploy restart --service=moodle

# Backup manual
dokploy backup --project=moodle-platform --type=database
```

## 🆚 Dokploy vs Otras Alternativas

| Característica | Dokploy | Manual Docker | Portainer | Kubernetes |
|----------------|---------|---------------|-----------|------------|
| **Simplicidad** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐ |
| **SSL Automático** | ✅ | ❌ | ❌ | ❌ |
| **UI Integrada** | ✅ | ❌ | ✅ | ✅ |
| **Multi-servidor** | ✅ | ❌ | ✅ | ✅ |
| **Backups** | ✅ | ❌ | ⚠️ | ⚠️ |
| **Curva Aprendizaje** | Baja | Alta | Media | Muy Alta |

## 🎯 Conclusión

Dokploy es ideal para Moodle porque:
- **Reduce complejidad** operacional
- **SSL y dominio** automático  
- **Interfaz unificada** para gestión
- **Escalabilidad** sin dolor de cabeza
- **Backups** integrados
- **Monitoreo** out-of-the-box

¡Perfecto para instituciones educativas que quieren enfocarse en la enseñanza, no en la infraestructura! 🎓