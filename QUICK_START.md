# 🚀 Guía Rápida - Configuración del Repositorio

## Tu información:
- **GitHub Username:** victoryoalli
- **Repository Name:** lemp-installer
- **Repository URL:** https://github.com/victoryoalli/lemp-installer
- **Website:** https://victoryoalli.me

---

## 📦 Paso 1: Crear el Repositorio en GitHub

1. Ve a: https://github.com/new
2. Configura:
   - **Repository name:** `lemp-installer`
   - **Description:** `Automated LEMP stack installation script for Laravel on Ubuntu 24.04`
   - **Public**
   - **NO** marcar "Add a README file"
   - **License:** MIT

3. Click "Create repository"

---

## 💻 Paso 2: Subir los Archivos

```bash
# Clonar el repositorio vacío
git clone https://github.com/victoryoalli/lemp-installer.git
cd lemp-installer

# Copiar todos los archivos de la carpeta github/ aquí
# (Todos los archivos que te proporcioné)

# Verificar que los archivos están
ls -la

# Deberías ver:
# .github/
# .gitignore
# CHANGELOG.md
# CONTRIBUTING.md
# LICENSE
# README.md
# SETUP_GUIDE.md
# install.sh

# Hacer el script ejecutable
chmod +x install.sh

# Añadir todos los archivos
git add .

# Crear commit inicial
git commit -m "feat: Initial release of LEMP installer v1.0.0"

# Subir a GitHub
git push origin main
```

---

## 🏷️ Paso 3: Crear el Release v1.0.0

```bash
# Crear tag
git tag -a v1.0.0 -m "Release v1.0.0 - Initial release"
git push origin v1.0.0
```

Luego en GitHub:
1. Ve a: https://github.com/victoryoalli/lemp-installer/releases
2. Click "Create a new release"
3. Selecciona tag: `v1.0.0`
4. Title: `v1.0.0 - Initial Release`
5. Description:

```markdown
## 🎉 Initial Release

First stable release of LEMP Stack Installer for Laravel on Ubuntu 24.04.

### ✨ Features
- Interactive installation with sensible defaults
- Nginx, MySQL 8.0+, PHP 8.3 installation
- Composer installation
- SSL/TLS configuration with Let's Encrypt
- System user setup for deployments
- SSH key generation for GitHub/GitLab
- UFW firewall configuration (optional)
- WordPress packages support (optional)
- Detailed installation logging

### 📦 Installation

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash
```

### 📚 Full Documentation
See the [README](https://github.com/victoryoalli/lemp-installer#readme) for complete documentation.
```

6. Click "Publish release"

---

## 🌐 Paso 4: Actualizar tu Blog

Agrega este código HTML a https://victoryoalli.me/ubuntu-lemp-install:

```html
<!-- Instalación Automática -->
<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 12px; padding: 30px; margin: 30px 0; color: white; box-shadow: 0 10px 30px rgba(0,0,0,0.2);">
    <h2 style="color: white; margin-top: 0; font-size: 28px; font-weight: bold;">
        🚀 Instalación Automática LEMP Stack
    </h2>
    
    <p style="font-size: 16px; opacity: 0.95; margin-bottom: 25px;">
        ¿No quieres seguir todos los pasos manualmente? Usa nuestro script automatizado que instala todo en 5-10 minutos:
    </p>
    
    <div style="background: rgba(0,0,0,0.3); border-radius: 8px; padding: 20px; margin: 20px 0; font-family: 'Courier New', monospace; position: relative;">
        <code style="color: #4ade80; font-size: 14px; display: block; word-wrap: break-word;">
            curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash
        </code>
        <button onclick="copyToClipboard('curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash')" 
                style="position: absolute; top: 15px; right: 15px; background: rgba(255,255,255,0.2); border: 1px solid rgba(255,255,255,0.3); color: white; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 12px; transition: all 0.3s;">
            📋 Copiar
        </button>
    </div>
    
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 25px 0;">
        <div style="background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px;">
            <div style="font-size: 24px; margin-bottom: 8px;">⚡</div>
            <div style="font-weight: bold; margin-bottom: 5px;">Rápido</div>
            <div style="font-size: 13px; opacity: 0.9;">5-10 minutos</div>
        </div>
        <div style="background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px;">
            <div style="font-size: 24px; margin-bottom: 8px;">🔒</div>
            <div style="font-weight: bold; margin-bottom: 5px;">SSL Incluido</div>
            <div style="font-size: 13px; opacity: 0.9;">Let's Encrypt</div>
        </div>
        <div style="background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px;">
            <div style="font-size: 24px; margin-bottom: 8px;">💬</div>
            <div style="font-weight: bold; margin-bottom: 5px;">Interactivo</div>
            <div style="font-size: 13px; opacity: 0.9;">Con defaults</div>
        </div>
        <div style="background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px;">
            <div style="font-size: 24px; margin-bottom: 8px;">📦</div>
            <div style="font-weight: bold; margin-bottom: 5px;">Open Source</div>
            <div style="font-size: 13px; opacity: 0.9;">MIT License</div>
        </div>
    </div>
    
    <details style="margin-top: 20px; background: rgba(0,0,0,0.2); padding: 20px; border-radius: 8px; cursor: pointer;">
        <summary style="font-weight: bold; font-size: 16px; outline: none; cursor: pointer;">
            📚 ¿Prefieres revisar el código primero?
        </summary>
        <div style="margin-top: 15px; padding-top: 15px; border-top: 1px solid rgba(255,255,255,0.2);">
            <p style="font-size: 14px; margin-bottom: 15px;">El código es 100% open source. Puedes revisarlo antes de ejecutar:</p>
            <div style="background: rgba(0,0,0,0.3); border-radius: 6px; padding: 15px; margin: 10px 0; font-family: 'Courier New', monospace;">
                <code style="color: #4ade80; font-size: 13px; display: block;">
                    # Ver el código en GitHub<br>
                    # https://github.com/victoryoalli/lemp-installer<br><br>
                    # Descargar y revisar<br>
                    curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh -o install.sh<br>
                    less install.sh<br><br>
                    # Ejecutar<br>
                    chmod +x install.sh<br>
                    sudo ./install.sh
                </code>
            </div>
        </div>
    </details>
    
    <div style="margin-top: 25px; padding-top: 20px; border-top: 1px solid rgba(255,255,255,0.2);">
        <a href="https://github.com/victoryoalli/lemp-installer" target="_blank" 
           style="display: inline-block; background: rgba(255,255,255,0.2); color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: bold; transition: all 0.3s; border: 2px solid rgba(255,255,255,0.3);">
            ⭐ Ver en GitHub
        </a>
        <span style="margin-left: 15px; font-size: 14px; opacity: 0.9;">
            ¿Te fue útil? Dale una estrella ⭐
        </span>
    </div>
</div>

<script>
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(function() {
        event.target.textContent = '✅ Copiado!';
        setTimeout(function() {
            event.target.textContent = '📋 Copiar';
        }, 2000);
    }, function(err) {
        console.error('Error al copiar: ', err);
    });
}
</script>

<style>
details[open] summary {
    margin-bottom: 15px;
}
</style>
```

---

## 🧪 Paso 5: Probar la Instalación

En un servidor de prueba (VM, DigitalOcean, AWS, etc.):

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash
```

---

## ⚙️ Paso 6: Configurar el Repositorio

1. Ve a: https://github.com/victoryoalli/lemp-installer
2. Click en ⚙️ junto a "About"
3. Configura:
   - **Website:** `https://victoryoalli.me/ubuntu-lemp-install`
   - **Topics:** `ubuntu`, `lemp`, `laravel`, `nginx`, `mysql`, `php`, `installer`, `automation`, `devops`, `bash-script`

4. En Settings > Features:
   - ✅ Issues
   - ✅ Discussions (opcional)

---

## 📣 Paso 7: Compartir

### Tweet de ejemplo:

```
🚀 Acabo de publicar LEMP Installer - un script open source para instalar 
Nginx + MySQL + PHP 8.3 optimizado para Laravel en Ubuntu 24.04

✅ Instalación en 1 línea
✅ SSL automático con Let's Encrypt
✅ Interactivo con valores por defecto
✅ 100% open source (MIT)

curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash

⭐ https://github.com/victoryoalli/lemp-installer

#Laravel #PHP #Ubuntu #DevOps #OpenSource
```

---

## 🔗 Links Importantes

- **Repositorio:** https://github.com/victoryoalli/lemp-installer
- **Blog Post:** https://victoryoalli.me/ubuntu-lemp-install
- **Script directo:** https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh
- **Issues:** https://github.com/victoryoalli/lemp-installer/issues
- **Releases:** https://github.com/victoryoalli/lemp-installer/releases

---

## 📋 Comando Final de Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash
```

O descarga y revisa primero:

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh -o install.sh
less install.sh
chmod +x install.sh
sudo ./install.sh
```

---

## ✅ Checklist

- [ ] Repositorio creado en GitHub
- [ ] Archivos subidos (commit + push)
- [ ] Release v1.0.0 creado
- [ ] About configurado (website + topics)
- [ ] Script probado en servidor de prueba
- [ ] Blog actualizado con widget HTML
- [ ] Tweet/post en redes sociales

---

¡Todo listo! 🎉
