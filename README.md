# BASH SCRIPTS
Repositorio para alojar scripts destinados a distribuciones Ubuntu/Debian


## Ubuntu Server Setup: Docker + Utils (basic-server-docker-setup.sh)

Este script automatiza la configuración básica de un servidor Ubuntu con:

- Actualización del sistema
- Instalación de Docker
- Añadir usuario al grupo `docker`
- Instalación de utilidades (`micro`, `tree`, `dops`)
- Creación de `/opt/docker` con permisos adecuados

## 🚀 Instalación rápida

### Usando `curl` 
```bash
curl -fsSL https://raw.githubusercontent.com/darkbox/ubuntu-scripts/main/basic-server-docker-setup.sh | sudo bash
```

### Usando `wget`
```bash
wget -qO- https://raw.githubusercontent.com/darkbox/ubuntu-scripts/main/basic-server-docker-setup.sh | sudo bash
```


