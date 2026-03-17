# Sparkle-test: Instrucciones de configuración

Este archivo describe lo que necesitas hacer después de clonar este repositorio para compilar y ejecutar **Sparkle-test**, una app hecha en SwiftUI para macOS con aislamiento (`sandbox`) que utiliza el *framework* de actualizaciones Sparkle (v2.x).

## 1. Requisitos previos

| Requisito | Versión |
|---|---|
| Xcode | 15+ |
| macOS | 13 Sonoma o posterior |
| Apple ID o Apple Developer | Necesaria para la firma de código |
| Sparkle | 2.x — añadido mediante Swift Package Manager |

## 2. Abrir el proyecto en Xcode

1. Abre `Sparkle-test.xcodeproj` en Xcode.
2. Xcode resolverá automáticamente la dependencia del paquete Swift **Sparkle** desde  
   `https://github.com/sparkle-project/Sparkle` (versión ≥ 2.0.0).  
   Espera a que el indicador de progreso "Resolving Package Graph" termine.

## 3. Configurar la firma de código

1. En Xcode, selecciona el proyecto **Sparkle-test** en el Navegador de proyectos.
2. Selecciona el `target` **Sparkle-test** → **Signing & Capabilities**.
3. En **Signing**:
   - Establece **Team** con tu Apple ID.
   - Mantén **Automatically manage signing** activado.
   - Establece **Sign to Run Locally**
   - El **Bundle Identifier** está preconfigurado como `com.perez987.Sparkle-test`.

### Sobre la firma "ad-hoc" con tu Apple ID

Para usuarios que ejecuten esta app, no necesitan un certificado de Developer ID pero recibirán una advertencia de Gatekeeper la primera vez que ejecuten la app.

En versiones anteriores a Sequoia, la advertencia de Gatekeeper para archivos descargados de Internet tenía una solución sencilla: aceptar la advertencia al abrir el archivo o hacer clic derecho → Abrir.

Pero en Sequoia y Tahoe la advertencia es más alarmante y podría inquietar al usuario. La solución es eliminar el atributo `com.apple.quarantine` para que, a partir de ese momento, puedas ejecutar la app sin problemas.

Puedes leer sobre esto en [La app está dañada y no se puede abrir](App-damaged-es.md).

## 4. Generar las claves EdDSA de Sparkle

Sparkle 2 utiliza firmas EdDSA (`Ed25519`) para verificar los paquetes de actualización.  
Debes generar un par de claves y añadir la **clave pública** a `Info.plist`.

### Pasos

1. Localiza `generate_keys` dentro del paquete Sparkle (Xcode descarga los paquetes en `~/Library/Developer/Xcode/DerivedData/<proyecto>/SourcePackages/`) o descarga `Sparkle-2.x.x.tar.xz` desde las [descargas](https://github.com/sparkle-project/Sparkle/releases) de GitHub
2. Extrae la distribución y ejecuta `generate_keys`

```bash
./bin/generate_keys
```

Este comando:

- Imprime una **clave privada** — por defecto, Sparkle la guarda en el Keychain de macOS. **Nunca la incluyas en el repositorio.**
- Imprime una **clave pública** (cadena en Base64).

### Añadir la clave pública a Info.plist

Añade esto al archivo Info.plist:

```xml
<key>SUPublicEDKey</key>
<string>TU_CLAVE_PUBLICA_BASE64</string>
```

**Importante:** Con `SUPublicEDKey` erróneo, Sparkle se negará a instalar actualizaciones.

## 5. Configurar appcast.xml

Sparkle consulta un *feed* XML remoto ("appcast") para descubrir nuevas versiones.

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
      <pubDate>Tue, 17 Mar 2026 12:00:00 +0000</pubDate>
      <enclosure
        url="https://github.com/perez987/Sparkle-in-a-sandboxed-app/releases/download/1.0.1/Sparkle-test-1.0.1.zip"
        sparkle:edSignature="FIRMA_EdDSA"
        length="1234567"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
```

#### Componentes del archivo appcast.xml

- `link`: dirección web del repositorio
- `language`: lenguage predefinido
- `item`: permite tener varias versiones en el mismo appcast
- `title`: número de versión de la app
- `description` vacía: Sparkle muestra un diálogo de actualización pequeño, sin notas de versión
- `description` con texto HTML entre CDATA etiquetas HTML: Sparkle muestra un diálogo más grande con notas de la versión
- `enclosure`: datos específicos de la versión
	- `url` -> enlace al archivo ZIP
	- `sparkle:version` -> número de compilación del proyecto(`CURRENT_PROJECT_VERSION` = `CFBundleVersion`)
	- `sparkle:shortVersionString`-> número de versión de la app (`MARKETING_VERSION`)
	- `pubDate`-> fecha de publicación
	- `length` -> tamaño del ZIP
	- `sparkle:edSignature` -> firma pública EdDSA para verificar la integridad de la actualización
	- `type` -> "application/octet-stream"
	- `minimumSystemVersion` -> version mínima de macOS.

### 5b. Firmar el paquete de actualización

```bash
# Genera .zip de la .app con la nueva versión:
zip -r Sparkle-test-1.1.zip Sparkle-test.app

# Fírmalo con tu clave privada usando la herramienta sign_update de Sparkle:
./bin/sign_update Sparkle-test-1.1.zip
```

Se muestra el tamaño en bytes (`length`) y la firma EdDSA (`sparkle:edSignature`) para rellenar el archivo appcast.

### 5c. Alojar el Appcast

Sube `appcast.xml` a la raíz del repositorio y el archivo `.zip` a la página de *releases*.

### 5d. Actualizar Info.plist

Rellena el valor de la propiedad `SUFeedURL` en `Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/perez987/Sparkle-in-a-sandboxed-app/main/appcast.xml</string>
```

## 6. Explicación del archivo Entitlements

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

**¿Por qué las excepciones temporales?**

Sparkle 2 usa dos servicios XPC privados incluidos dentro de `Sparkle.framework`:

- `Sparkle Downloader.xpc` — descarga actualizaciones de la red
- `Sparkle Installer.xpc` — aplica las actualizaciones a la app

Las excepciones `mach-lookup` permiten a la app con `sandbox` encontrar y comunicarse con estos servicios.

## 7. Compilar y ejecutar

1. Selecciona el esquema **Sparkle-test** y tu Mac como destino.
2. Pulsa **⌘R** para compilar y ejecutar.
3. La ventana de la app muestra la versión actual (versión de marketing y número de compilación).
4. Un ítem **Check for Updates…** está disponible en el menú de la aplicación (también accesible con **⌘U**). Está desactivado hasta que Sparkle termina su comprobación inicial; se activa después de unos segundos.

## 8. Probar el flujo de actualización

Para probar un ciclo de actualización completo sin un servidor, puedes usar un servidor HTTP local:

```bash
# Sirve archivos en localhost:8080
python3 -m http.server 8080 --directory /ruta/a/tus/archivos/de/actualización
```

Apunta temporalmente `SUFeedURL` en `Info.plist` a `http://localhost:8080/appcast.xml`.

> **Nota:** Para pruebas locales puedes omitir `SUPublicEDKey` y eliminar la clave `SURequireSignedFeed`, pero **vuelve a activarlas siempre** en producción.

## 9. Crear la app para distribución

Dado que esta app **no será notarizada** (está firmada ad-hoc con tu Apple ID):

1. Archiva la app: **Product → Archive** en Xcode.
2. En el Organizador, haz clic en **Distribute App** → **Direct Distribution** (o **Copy App**).
3. El paquete `.app` resultante puede ejecutarse en **tu propio Mac** sin problemas de Gatekeeper  
   (Gatekeeper la bloqueará en otros Macs a menos que el usuario elimine el atributo de cuarentena).

## 10. Estructura de archivos del proyecto

```
Sparkle-test/
├── Sparkle-test.xcodeproj/             Archivo de proyecto Xcode)
│   └── project.pbxproj
├── Sparkle-test/                       Código fuente Swift y recursos
│   ├── Sparkle_testApp.swift           Punto de entrada de la app; crea UpdaterController y añade "Check for Updates…" al menú de la app
│   ├── Views/
│   │   └── ContentView.swift           Ventana principal: icono, título y texto de versión/compilación
│   ├── Model/
│   │   └── UpdateController.swift      ObservableObject (UpdaterController) que envuelve SPUStandardUpdaterController y publica canCheckForUpdates
│   ├── Info.plist                      Metadatos de la app + claves de Sparkle (SUFeedURL, SUPublicEDKey…)
│   ├── Sparkle-test.entitlements       Sandbox + red + excepciones de Sparkle
│   └── Assets.xcassets/                Icono de la app + color de énfasis
└── LICENSE
```

## 11. Configuraciones clave de Info.plist para Sparkle 2

| Clave | Descripción |
|---|---|
| `SUFeedURL` | **Obligatorio**: URL HTTPS a tu `appcast.xml` |
| `SUPublicEDKey` | **Obligatorio en producción**: Clave pública EdDSA en Base64 para verificación de actualizaciones |
| `SUEnableInstallerLauncherService` | **Obligatorio con sandbox**: Permite a Sparkle lanzar su servicio instalador XPC |
| `SUEnableSystemProfiling` | Establece `false` para desactivar el análisis anónimo |
| `SUScheduledCheckInterval` | Segundos entre comprobaciones automáticas de actualizaciones (configurado a 604800 = 1 semana en este proyecto) |

## 12. Solución de problemas

| Síntoma | Causa probable | Solución |
|---|---|---|
| "Check for Updates" siempre desactivado | El actualizador no pudo iniciarse | Comprueba la Consola para errores de Sparkle; asegúrate de que `SUFeedURL` sea accesible |
| Violación de sandbox en la Consola | Falta *entitlements* | Verifica que las excepciones `mach-lookup` en el archivo entitlements coincidan con  `bundle ID` |
| La descarga de la actualización falla silenciosamente | Falta *entitlement* `network.client` o URL incorrecta | Comprueba *entitlements*; verifica que la URL del appcast sea HTTPS |
| "La actualización no puede instalarse" | Falta `SUEnableInstallerLauncherService` | Añade/verifica que esa clave sea `true` en `Info.plist` |
| La verificación de firma falla | Falta `SUPublicEDKey` o es incorrecta | Regenera las claves y actualiza `Info.plist` |
| La app no se abre en otro Mac | No notarizada | - Clic derecho en la app → Abrir<br>- Eliminar el atributo de cuarentena<br>- Si tienes cuenta de Apple Developer, notariza para distribución |

## Referencias

- [Documentación de Sparkle](https://sparkle-project.org/documentation/)
- [Guía de Sandboxing de Sparkle](https://sparkle-project.org/documentation/sandboxing/)
- [Publicación de actualizaciones con Sparkle](https://sparkle-project.org/documentation/publishing/)
- [Releases de Sparkle en GitHub](https://github.com/sparkle-project/Sparkle/releases)

---
🇬🇧 [Versión en inglés](HOWTO-Sparkle.md)
