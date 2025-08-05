#!/bin/bash

# Solicitar permisos de root
if [[ $EUID -ne 0 ]]; then
  echo "Este script necesita ejecutarse como root. Intenta con: sudo $0"
  exit 1
fi

# Actualizar repositorios y sistema
echo "Actualizando repositorios y sistema..."
apt update && apt upgrade -y

# Instalar paquetes básicos
echo "Instalando paquetes micro y tree..."
apt install -y micro tree

# Descargar e instalar Docker
echo "Descargando script oficial de instalación de Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh

echo "Instalando Docker..."
sh ./get-docker.sh

# Asegurar que el usuario actual está en el grupo docker
CURRENT_USER=$(logname)
if id -nG "$CURRENT_USER" | grep -qw docker; then
  echo "El usuario '$CURRENT_USER' ya pertenece al grupo docker."
else
  echo "Añadiendo al usuario '$CURRENT_USER' al grupo docker..."
  usermod -aG docker "$CURRENT_USER"
  echo "El usuario '$CURRENT_USER' ha sido añadido al grupo docker. Es necesario cerrar sesión para que surta efecto."
fi

# Instalar dops (better-docker-ps)
echo "Instalando 'dops' (better-docker-ps)..."
wget -q "https://github.com/Mikescher/better-docker-ps/releases/latest/download/dops_linux-amd64-static" -O "/usr/local/bin/dops"
chmod +x "/usr/local/bin/dops"
echo "'dops' instalado correctamente en /usr/local/bin"

# Crear carpeta /opt/docker
echo "Creando carpeta /opt/docker..."
mkdir -p /opt/docker
chown "$CURRENT_USER:docker" /opt/docker
chmod 775 /opt/docker

echo "Instalación y configuración completadas."
