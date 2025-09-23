#!/bin/bash

set -euo pipefail

# --- Root check ---
# Require root privileges to run this script
if [[ $EUID -ne 0 ]]; then
  echo "Este script necesita ejecutarse como root. Intenta con: sudo $0"
  exit 1
fi

# Figure out the invoking user (prefer SUDO_USER when using sudo)
CURRENT_USER="${SUDO_USER:-$(logname)}"

echo "Detectando gestor de paquetes (DNF)..."
PKG_MGR="dnf"
command -v dnf >/dev/null 2>&1 || { echo "DNF no encontrado. ¿Es AlmaLinux?"; exit 1; }

# --- Refresh and base updates ---
echo "Actualizando repositorios y sistema..."
$PKG_MGR -y makecache
$PKG_MGR -y upgrade

# --- Base tooling required to fetch/install stuff ---
echo "Instalando utilidades base (curl, wget, ca-certificates, tar)..."
$PKG_MGR -y install curl wget ca-certificates tar

# --- EPEL for extra packages like 'micro' ---
echo "Habilitando EPEL..."
$PKG_MGR -y install epel-release

# --- Basic packages ---
echo "Instalando paquetes: micro y tree..."
$PKG_MGR -y install micro tree

# --- Docker install via official convenience script ---
echo "Descargando script oficial de instalación de Docker..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh

echo "Instalando Docker..."
sh /tmp/get-docker.sh

# --- Enable and start Docker service ---
echo "Habilitando y arrancando el servicio Docker..."
systemctl enable --now docker

# --- Add current user to docker group ---
# Ensure the 'docker' group exists (created by Docker packages)
if getent group docker >/dev/null; then
  if id -nG "$CURRENT_USER" | grep -qw docker; then
    echo "El usuario '$CURRENT_USER' ya pertenece al grupo docker."
  else
    echo "Añadiendo al usuario '$CURRENT_USER' al grupo docker..."
    usermod -aG docker "$CURRENT_USER"
    echo "El usuario '$CURRENT_USER' ha sido añadido al grupo docker. Cierra sesión y vuelve a entrar para aplicar los cambios."
  fi
else
  echo "Grupo 'docker' no encontrado. ¿Falló la instalación de Docker?"
  exit 1
fi

# --- Install dops (better-docker-ps) ---
echo "Instalando 'dops' (better-docker-ps)..."
ARCH="$(uname -m)"
# Map common arch names to release asset suffix
case "$ARCH" in
  x86_64|amd64) DOPS_ASSET="dops_linux-amd64-static" ;;
  aarch64|arm64) DOPS_ASSET="dops_linux-arm64-static" ;;
  *) echo "Arquitectura '$ARCH' no soportada por 'dops' precompilado."; exit 1 ;;
esac
wget -q "https://github.com/Mikescher/better-docker-ps/releases/latest/download/${DOPS_ASSET}" -O "/usr/local/bin/dops"
chmod +x "/usr/local/bin/dops"
echo "'dops' instalado correctamente en /usr/local/bin"

# --- Create /opt/docker directory with sane perms ---
echo "Creando carpeta /opt/docker..."
mkdir -p /opt/docker
chown "$CURRENT_USER:docker" /opt/docker
chmod 775 /opt/docker

echo "Instalación y configuración completadas."
echo "Recuerda cerrar sesión y volver a entrar para usar Docker sin sudo."
