# Sparkle-test: Instrucciones de configuración

Este archivo describe todo lo que necesitas hacer después de clonar este repositorio para compilar y ejecutar **Sparkle-test**, una app macOS SwiftUI con sandbox que utiliza el framework de actualizaciones [Sparkle](https://sparkle-project.org/) (v2.x).

## 1. Requisitos previos

| Requisito | Versión |
|---|---|
| Xcode | 15+ |
| macOS | 13 Sonoma o posterior (host de compilación) |
| Cuenta de Apple Developer | Necesaria para la firma de código |
| Sparkle | 2.x — añadido mediante Swift Package Manager |

## 2. Abrir el proyecto en Xcode

1. Abre `Sparkle-test.xcodeproj` en Xcode.
2. Xcode resolverá automáticamente la dependencia del paquete Swift **Sparkle** desde  
   `https://github.com/sparkle-project/Sparkle` (versión ≥ 2.0.0).  
   Espera a que el indicador "Resolving Package Graph" termine.

## 3. Configurar la firma de código

1. En Xcode, selecciona el proyecto **Sparkle-test** en el Navegador de proyectos.
2. Selecciona el target **Sparkle-test** → **Signing & Capabilities**.
3. En **Signing**:
   - Establece **Team** con tu Apple ID.
   - Mantén **Automatically manage signing** activado.
   - Establece **Sign to Run Locally**
   - El **Bundle Identifier** está preconfigurado como `com.perez987.Sparkle-test`.

### Sobre la firma "ad-hoc" con tu Apple ID

Para otros usuarios que ejecuten esta app (fuera del App Store), no necesitan un certificado de Developer ID, pero recibirán una advertencia de Gatekeeper la primera vez que ejecuten la app.

En versiones anteriores a Sequoia, la advertencia de Gatekeeper para archivos descargados de Internet tenía una solución sencilla: aceptar la advertencia al abrir el archivo o hacer clic derecho sobre él >> Abrir.

Pero en Sequoia y Tahoe, la advertencia es más alarmante y podría inquietar al usuario. La solución es eliminar el atributo `com.apple.quarantine` para que, a partir de ese momento, puedas ejecutar la app sin problemas.

Puedes leer sobre esto en [La app está dañada y no se puede abrir](APP-damaged.md).

## 4. Generar las claves EdDSA de Sparkle

Sparkle 2 utiliza firmas EdDSA (`Ed25519`) para verificar los paquetes de actualización.  
Debes generar un par de claves y añadir la **clave pública** a `Info.plist`.

### Pasos

1. Localiza `generate_keys` dentro del paquete Sparkle resuelto (Xcode descarga los paquetes en `~/Library/Developer/Xcode/DerivedData/<proyecto>/SourcePackages/`) o descarga `Sparkle-2.x.x.tar.xz` desde las [releases](https://github.com/sparkle-project/Sparkle/releases) de GitHub
2. Extrae la distribución binaria y ejecuta `generate_keys`

```bash
./bin/generate_keys
```

La herramienta:

- Imprimirá una **clave privada** — por defecto, Sparkle la guarda en el Keychain de macOS. **Nunca la incluyas en el repositorio.**
- Imprimirá una **clave pública** (cadena en Base64).

### Añadir la clave pública a Info.plist

Abre `Sparkle-test/Info.plist` y reemplaza `REPLACE_WITH_YOUR_PUBLIC_ED_KEY`:

```xml
<key>SUPublicEDKey</key>
<string>TU_CLAVE_PUBLICA_BASE64_AQUI</string>
```

**Importante:** Sin el `SUPublicEDKey` correcto, Sparkle se negará a instalar actualizaciones.

## 5. Configurar un feed Appcast

Sparkle consulta un feed XML remoto ("appcast") para descubrir nuevas versiones.

### 5a. Crear el XML del Appcast

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Sparkle-test</title>
    <item>
      <title>Version 1.0.1</title>
      <sparkle:version>4</sparkle:version>
      <sparkle:shortVersionString>1.0.1</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <pubDate>Fri, 01 Jan 2025 12:00:00 +0000</pubDate>
      <enclosure
        url="https://github.com/perez987/Sparkle-test/releases/download/1.0.1/Sparkle-test-1.0.1.zip"
        sparkle:edSignature="TU_FIRMA_ED"
        length="1234567"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
```

### 5b. Firmar el paquete de actualización

```bash
# Genera el .zip del bundle .app de la nueva versión
zip -r Sparkle-test-1.1.zip Sparkle-test.app

# Fírmalo con tu clave privada usando la herramienta sign_update de Sparkle
./bin/sign_update Sparkle-test-1.1.zip
# → imprime el tamaño (en bytes) y el sparkle:edSignature para pegar en el appcast
```

### 5c. Alojar el Appcast

Sube `appcast.xml` a la raíz del repositorio y el archivo `.zip` a la página de releases.

### 5d. Actualizar Info.plist

Reemplaza el marcador `SUFeedURL` en `Sparkle-test/Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/usuario_GitHub/repo_GitHub/main/appcast.xml</string>
```

## 6. Explicación de los Sandbox Entitlements

El archivo `Sparkle-test.entitlements` contiene:

- com.apple.security.app-sandbox: true
   - Activa el Sandbox de apps de macOS
- com.apple.security.network.client: true
   - Permite conexiones salientes (appcast + descarga de actualizaciones)
- com.apple.security.files.user-selected.read-only: true
   - Archivos seleccionados por el usuario: acceso de solo lectura
- com.apple.security.temporary-exception.mach-lookup.global-name: […-spks, …-spki]
   - Permite la comunicación con los servicios XPC helper de Sparkle
- com.apple.security.temporary-exception.shared-preference.read-write: [bundle-id]
   - Permite a Sparkle almacenar el estado de las actualizaciones en los valores predeterminados compartidos

**¿Por qué excepciones temporales?**

Sparkle 2 usa dos servicios XPC privados incluidos dentro de `Sparkle.framework`:

- `Sparkle Downloader.xpc` — descarga actualizaciones de la red
- `Sparkle Installer.xpc` — aplica las actualizaciones al bundle de la app

Las excepciones `mach-lookup` permiten a la app con sandbox encontrar y comunicarse con estos servicios.

## 7. Compilar y ejecutar

1. Selecciona el scheme **Sparkle-test** y tu Mac como destino.
2. Pulsa **⌘R** para compilar y ejecutar.
3. La ventana de la app muestra la versión actual y un botón **Check for Updates…**.
4. El botón está desactivado hasta que Sparkle termina su comprobación inicial; se activa después de unos segundos.

## 8. Probar el flujo de actualización (de extremo a extremo)

Para probar un ciclo de actualización completo sin un servidor público, puedes usar un servidor HTTP local:

```bash
# Sirve archivos en localhost:8080
python3 -m http.server 8080 --directory /ruta/a/tus/archivos/de/actualización
```

Apunta temporalmente `SUFeedURL` en `Info.plist` a `http://localhost:8080/appcast.xml`.

> **Nota:** Para pruebas locales puedes omitir `SUPublicEDKey` y eliminar la clave `SURequireSignedFeed`, pero **vuelve a activarlas siempre** en producción.

## 9. Crear una build distribuible

Dado que esta app **no será notarizada** (firmada ad-hoc con tu Apple ID):

1. Archiva la app: **Product → Archive** en Xcode.
2. En el Organizador, haz clic en **Distribute App** → **Direct Distribution** (o **Copy App**).
3. El bundle `.app` resultante puede ejecutarse en **tu propio Mac** sin problemas de Gatekeeper  
   (Gatekeeper lo bloqueará en otros Macs a menos que esté notarizado o el usuario elimine el atributo de cuarentena).

## 10. Estructura de archivos del proyecto

```
Sparkle-test/
├── Sparkle-test.xcodeproj/             Proyecto Xcode (abre este)
│   └── project.pbxproj
├── Sparkle-test/                       Código fuente Swift y recursos
│   ├── Sparkle_testApp.swift           Punto de entrada de la app; inicializa SPUStandardUpdaterController
│   ├── ContentView.swift               Ventana principal: texto de versión + botón Check for Updates
│   ├── CheckForUpdatesViewModel.swift  ObservableObject que refleja canCheckForUpdates
│   ├── Info.plist                      Metadatos de la app + claves de Sparkle (SUFeedURL, SUPublicEDKey…)
│   ├── Sparkle-test.entitlements       Sandbox + red + excepciones mach de Sparkle
│   └── Assets.xcassets/                Icono de la app + color de énfasis
└── LICENSE
```

## 11. Configuraciones clave de Info.plist para Sparkle 2

| Clave | Descripción |
|---|---|
| `SUFeedURL` | **Obligatorio**: URL HTTPS a tu `appcast.xml` |
| `SUPublicEDKey` | **Obligatorio en producción**: Clave pública Ed25519 en Base64 para verificación de actualizaciones |
| `SUEnableInstallerLauncherService` | **Obligatorio con sandbox**: Permite a Sparkle lanzar su servicio XPC instalador |
| `SUEnableSystemProfiling` | Establece `false` para desactivar el análisis anónimo |
| `SUScheduledCheckInterval` | Segundos entre comprobaciones automáticas de actualizaciones (predeterminado: 86400 = 1 día) |

## 12. Solución de problemas

| Síntoma | Causa probable | Solución |
|---|---|---|
| "Check for Updates" siempre desactivado | El actualizador no pudo iniciarse | Comprueba la Consola para errores de Sparkle; asegúrate de que `SUFeedURL` sea accesible |
| Violación de sandbox en la Consola | Entitlement faltante | Verifica que las excepciones `mach-lookup` en el archivo de entitlements coincidan con el bundle ID |
| La descarga de la actualización falla silenciosamente | Entitlement `network.client` faltante o URL incorrecta | Comprueba los entitlements; verifica que la URL del appcast sea HTTPS |
| "La actualización no puede instalarse" | `SUEnableInstallerLauncherService` faltante | Añade/verifica que esa clave sea `true` en `Info.plist` |
| La verificación de firma falla | `SUPublicEDKey` incorrecto o faltante | Regenera las claves y actualiza `Info.plist` |
| La app no se abre en otro Mac | No notarizada | - Clic derecho en la app → Abrir<br>- Eliminar el atributo de cuarentena<br>- Si tienes cuenta de Apple Developer, notariza para distribución |

## Referencias

- [Documentación de Sparkle](https://sparkle-project.org/documentation/)
- [Guía de Sandboxing de Sparkle](https://sparkle-project.org/documentation/sandboxing/)
- [Publicación de actualizaciones con Sparkle](https://sparkle-project.org/documentation/publishing/)
- [Releases de Sparkle en GitHub](https://github.com/sparkle-project/Sparkle/releases)

---
🌐 [English version](HOWTO-Sparkle.md)
