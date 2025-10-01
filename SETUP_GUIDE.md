# Guía para Configurar el Repositorio de GitHub

## 📦 Paso 1: Crear el Repositorio en GitHub

### 1.1 Crear nuevo repositorio

1. Ve a https://github.com/new
2. Configura el repositorio:
   - **Repository name:** `lemp-installer`
   - **Description:** `Automated LEMP stack installation script for Laravel on Ubuntu 24.04`
   - **Public** (recomendado para scripts de instalación)
   - ✅ Add a README file (NO, ya tenemos uno)
   - ✅ Add .gitignore (NO, ya tenemos uno)
   - ✅ Choose a license: MIT

### 1.2 Clonar localmente (si es nuevo)

```bash
git clone https://github.com/victoryoalli/lemp-installer.git
cd lemp-installer
```

## 📁 Paso 2: Subir los Archivos

### 2.1 Copiar los archivos del directorio `github/`

Copia todos los archivos que te proporcioné:

```
lemp-installer/
├── .github/
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
└── install.sh
```

### 2.2 Commit y push

```bash
# Añadir todos los archivos
git add .

# Crear commit inicial
git commit -m "feat: Initial release of LEMP installer v1.0.0"

# Subir a GitHub
git push origin main
```

## 🏷️ Paso 3: Crear el Primer Release

### 3.1 Crear un tag

```bash
git tag -a v1.0.0 -m "Release v1.0.0 - Initial release"
git push origin v1.0.0
```

### 3.2 Crear release en GitHub

1. Ve a tu repositorio en GitHub
2. Click en "Releases" (lado derecho)
3. Click en "Create a new release"
4. Configura:
   - **Tag:** v1.0.0
   - **Release title:** v1.0.0 - Initial Release
   - **Description:** (Copia del CHANGELOG.md)
   
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

### 📚 Documentation
Full documentation available in the [README](https://github.com/victoryoalli/lemp-installer#readme)
```

5. Click "Publish release"

## 🌐 Paso 4: Actualizar tu Blog

### 4.1 Actualizar el post en victoryoalli.me/ubuntu-lemp-install

Agrega esta sección al principio o después de la introducción:

```html
<!-- Sección de instalación automática -->
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

<!-- Aquí continúa el contenido original del blog -->
<h2>Instalación Manual</h2>
<p>Si prefieres entender cada paso o necesitas personalizaciones específicas, continúa con la instalación manual...</p>
```

### 4.2 Reemplazar victoryoalli

**IMPORTANTE:** En todos los archivos, reemplaza `victoryoalli` con tu nombre de usuario real de GitHub.

Archivos que necesitan actualización:
- `README.md` (múltiples lugares)
- `install.sh` (comentarios en el header)
- El código HTML para tu blog (arriba)

Puedes hacer un buscar y reemplazar:

```bash
# En Linux/Mac
find . -type f -exec sed -i 's/victoryoalli/tu_usuario_github/g' {} +

# Manualmente verifica cada archivo
grep -r "victoryoalli" .
```

## 🔧 Paso 5: Configurar GitHub Repository Settings

### 5.1 Configurar About

1. Ve a tu repositorio
2. Click en el ⚙️ (Settings) junto a "About"
3. Configura:
   - **Website:** `https://victoryoalli.me/ubuntu-lemp-install`
   - **Topics:** `ubuntu`, `lemp`, `laravel`, `nginx`, `mysql`, `php`, `installer`, `automation`, `devops`, `bash-script`

### 5.2 Habilitar Issues y Discussions (opcional)

1. Ve a Settings del repositorio
2. En "Features":
   - ✅ Issues
   - ✅ Discussions (opcional, para preguntas de la comunidad)

## 📊 Paso 6: Añadir Badges al README (opcional)

GitHub genera automáticamente algunos badges. Puedes personalizar el README con más información:

```markdown
![GitHub release (latest by date)](https://img.shields.io/github/v/release/victoryoalli/lemp-installer)
![GitHub](https://img.shields.io/github/license/victoryoalli/lemp-installer)
![GitHub issues](https://img.shields.io/github/issues/victoryoalli/lemp-installer)
![GitHub stars](https://img.shields.io/github/stars/victoryoalli/lemp-installer?style=social)
```

## 🎯 Paso 7: Probar la Instalación

Antes de publicar, prueba el comando completo:

```bash
# En una VM o servidor de prueba
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash
```

## 📣 Paso 8: Promocionar

### 8.1 Compartir en redes sociales
- Twitter/X
- LinkedIn
- Reddit (r/laravel, r/PHP, r/webdev)
- Dev.to

### 8.2 Ejemplo de post para Twitter/X:

```
🚀 Nuevo proyecto open source: LEMP Installer

Instala Nginx + MySQL + PHP 8.3 optimizado para Laravel en Ubuntu 24.04 con un solo comando.

✅ Interactivo
✅ SSL automático
✅ 100% open source

curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash

⭐ https://github.com/victoryoalli/lemp-installer

#Laravel #PHP #Ubuntu #DevOps
```

### 8.3 Agregar al blog

Menciona el repositorio de GitHub al final del post:

```markdown
## Script de Instalación Automática

Todo este proceso está automatizado en un script open source:
- 🔗 GitHub: https://github.com/victoryoalli/lemp-installer
- 📦 Versión actual: v1.0.0
- 📝 Licencia: MIT

¿Te fue útil? Dale una estrella ⭐ en GitHub!
```

## ✅ Checklist Final

Antes de considerar el proyecto listo:

- [ ] Repositorio creado en GitHub
- [ ] Todos los archivos subidos
- [ ] README actualizado con tu usuario
- [ ] Release v1.0.0 creado
- [ ] Script probado en Ubuntu 24.04
- [ ] Script probado en Ubuntu 22.04 (opcional)
- [ ] Blog actualizado con el widget
- [ ] Links verificados (no enlaces rotos)
- [ ] Issues templates funcionando
- [ ] License file presente
- [ ] .gitignore configurado

## 🔄 Mantenimiento Futuro

### Cuando hagas cambios:

```bash
# 1. Hacer cambios
nano install.sh

# 2. Actualizar CHANGELOG.md
nano CHANGELOG.md

# 3. Commit
git add .
git commit -m "fix: descripción del cambio"

# 4. Push
git push origin main

# 5. Para releases importantes, crear nuevo tag
git tag -a v1.0.1 -m "Release v1.0.1 - Bug fixes"
git push origin v1.0.1

# 6. Crear release en GitHub
# (ir a GitHub y crear el release desde la interfaz)
```

## 📞 Soporte

Si tienes dudas durante el setup:
1. Revisa esta guía
2. Consulta la documentación de GitHub
3. Abre un issue en el repositorio

---

¡Éxito con tu proyecto! 🎉
