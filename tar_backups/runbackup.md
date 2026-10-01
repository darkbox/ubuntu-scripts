# *runbackup*

Script `bash` para generar copias de seguridad utilizando `tar` y un patrón de rotación GPC (*Grandparent-Parent-Child*).

El objetivo es mantener diferentes puntos de restauración diarios, semanales y mensuales, reutilizando nombres de archivo de forma rotativa.

# Configuración

Editar el script y seleccionar los directorios o archivos a respaldar, así como el destino:

```bash
BACKUP_FILES=(/home /opt/docker)
BACKUP_DEST="/mnt/backup"
```

> **IMPORTANTE:** utilizar siempre rutas absolutas.

También se puede ajustar el espacio mínimo requerido antes de iniciar el respaldo:

```bash
MIN_DISK_MB=1000
```

El script genera un registro de actividad en:

```bash
/var/log/backup.log
```

# Rotación de respaldos

El script utiliza una rotación GPC (*Grandparent-Parent-Child*) que combina respaldos diarios, semanales y mensuales.

## Respaldos diarios

De domingo a viernes se genera un archivo asociado al día de la semana:

```text
hostname-Sunday.tgz
hostname-Monday.tgz
hostname-Tuesday.tgz
hostname-Wednesday.tgz
hostname-Thursday.tgz
hostname-Friday.tgz
```

Cada semana se sobrescribe el respaldo correspondiente al mismo día.

De esta forma se conservan varios puntos de restauración recientes.

## Respaldos semanales

Los sábados se genera un respaldo semanal utilizando cuatro posiciones:

```text
hostname-week1.tgz
hostname-week2.tgz
hostname-week3.tgz
hostname-week4.tgz
```

La posición utilizada depende del día del mes:

```text
Días  1-7   -> week1
Días  8-14  -> week2
Días 15-21  -> week3
Días 22-31  -> week4
```

Cada posición se reutiliza aproximadamente una vez al mes.

## Respaldos mensuales

El día 1 de cada mes se genera un respaldo mensual.

Se utilizan dos posiciones alternas:

```text
hostname-month1.tgz
hostname-month2.tgz
```

Los meses impares utilizan:

```text
hostname-month1.tgz
```

Los meses pares utilizan:

```text
hostname-month2.tgz
```

De esta forma siempre se conserva el respaldo mensual anterior mientras se genera el correspondiente al mes actual.

> Si el día 1 del mes coincide con sábado, tiene prioridad el respaldo mensual y no se genera el respaldo semanal de ese día.

## Resumen de la rotación

```text
Domingo a viernes  -> respaldo diario
Sábado              -> respaldo semanal
Día 1 de cada mes   -> respaldo mensual
```

Los archivos se sobrescriben de forma rotativa, por lo que el espacio ocupado permanece aproximadamente constante.

# Automatización

Mover el script a `/bin/` y asignarle permisos de ejecución:

```bash
sudo mv runbackup /bin/runbackup
sudo chmod +x /bin/runbackup
```

# Programar *CRON*

Editar el `crontab` del usuario `root`:

```bash
sudo crontab -e
```

Por ejemplo, para ejecutar el script todos los días a las 02:00:

```bash
0 2 * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/runbackup
```

> **IMPORTANTE:** utilizar rutas absolutas e incluir el `$PATH` completo antes del comando.

Para comprobar las tareas programadas:

```bash
sudo crontab -l
```

## Revisar logs

Mostrar las últimas líneas del registro:

```bash
tail /var/log/backup.log
```

Seguir el log en tiempo real:

```bash
tail -f /var/log/backup.log
```

## Revisar contenidos del `tar` sin extraer

```bash
tar -tzf backup.tgz
```

Para una vista más detallada:

```bash
tar -tvzf backup.tgz
```

También se puede buscar un archivo concreto:

```bash
tar -tzf backup.tgz | grep nombre_archivo
```

## Extraer contenidos

Extraer todo el contenido del respaldo en el directorio actual:

```bash
tar -xzf backup.tgz
```

Extraerlo en un directorio concreto:

```bash
mkdir -p /tmp/restore
tar -xzf backup.tgz -C /tmp/restore
```

Es recomendable extraer primero el respaldo en un directorio temporal y revisar su contenido antes de realizar una restauración sobre el sistema.

## Restaurar contenidos

Para restaurar el contenido directamente sobre el sistema:

```bash
sudo tar -xzpf backup.tgz -C /
```

La opción `-p` intenta conservar los permisos originales de los archivos.

> **PRECAUCIÓN:** este comando puede sobrescribir archivos existentes del sistema.

Antes de restaurar, se recomienda comprobar el contenido del respaldo:

```bash
tar -tzf backup.tgz
```

## Restaurar un archivo o directorio concreto

Primero localizar la ruta exacta almacenada dentro del archivo:

```bash
tar -tzf backup.tgz | grep ejemplo
```

Por ejemplo, si el respaldo contiene:

```text
home/user/config/
```

se puede extraer únicamente ese directorio:

```bash
tar -xzf backup.tgz home/user/config/
```

Para restaurarlo directamente sobre su ubicación original:

```bash
sudo tar -xzpf backup.tgz -C / home/user/config/
```

Para restaurar un único archivo:

```bash
sudo tar -xzpf backup.tgz -C / etc/ssh/sshd_config
```

> Las rutas almacenadas por `tar` normalmente aparecen sin `/` inicial, aunque originalmente fueran rutas absolutas.

## Comprobar integridad del respaldo

Se puede comprobar que el archivo puede leerse completamente sin extraerlo:

```bash
tar -tzf backup.tgz > /dev/null
```

Para comprobar el resultado:

```bash
tar -tzf backup.tgz > /dev/null && echo "OK" || echo "ERROR"
```