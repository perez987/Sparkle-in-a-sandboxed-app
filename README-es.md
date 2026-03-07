# Sistema de actualización Sparkle en una app SwiftUI con sandbox

Sitio de prueba para aprender a implementar el sistema de actualización Sparkle en una app macOS SwiftUI con sandbox que utiliza el framework de actualizaciones Sparkle (v2.x).

Implementar Sparkle en un proyecto SwiftUI de Xcode sin sandbox suele ser bastante sencillo y genera pocos problemas.

Sin embargo, muchos usuarios (yo incluido) encuentran que implementar Sparkle en una app con sandbox es considerablemente más difícil. Los problemas de seguridad y permisos frecuentemente provocan fallos. Este repositorio fue creado para probar una configuración funcional.

## Requisitos del proyecto y la app

Los requisitos del proyecto y la app fueron:

- La app debe tener sandbox, ya que mi reto es implementar Sparkle en apps con sandbox. Las apps sin sandbox son fáciles de configurar con Sparkle
- La app no está notarizada por Apple, solo firmada ad hoc con mi Apple ID
- El proyecto de Xcode debe tener un archivo `.entitlements`
- Las condiciones básicas del sandbox son:
   - archivos de usuario de solo lectura
   - conexiones salientes permitidas

Las instrucciones detalladas están disponibles en el archivo [HOWTO-Sparkle](HOWTO-Sparkle-es.md)

---
🌐 [English version](README.md)
