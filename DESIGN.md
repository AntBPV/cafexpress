---
name: "Caféxpress"
description: "Sistema visual del acceso Flutter Material 3, con Android como referencia."
colors:
  coffee: "#2D1C13"
  cream: "#FAF7F0"
  olive: "#536337"
  gold: "#D5AB66"
  on-primary-light: "#FFFFFF"
  primary-dark: "#C3D49B"
  on-primary-dark: "#253219"
  surface-dark: "#211B16"
  text-dark: "#F1E8DA"
  text-muted-light: "#75675C"
  text-muted-dark: "#C5B8A8"
  outline-light: "#8C8173"
  outline-dark: "#A19584"
  container-light: "#F0EADF"
  container-dark: "#342B22"
  secondary-light: "#825A22"
  field-dark: "#29221C"
typography:
  headline:
    fontFamily: "Roboto"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.8px"
  wordmark:
    fontFamily: "Roboto"
    fontSize: "24px"
    fontWeight: 800
    lineHeight: 1.33
    letterSpacing: "-0.6px"
  body:
    fontFamily: "Roboto"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0.5px"
  body-medium:
    fontFamily: "Roboto"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0.25px"
  body-small:
    fontFamily: "Roboto"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.33
    letterSpacing: "0.4px"
  button-label:
    fontFamily: "Roboto"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.43
    letterSpacing: "0.1px"
rounded:
  control: "12px"
spacing:
  icon-gap: "12px"
  sm: "16px"
  md: "24px"
  lg: "32px"
  section: "40px"
  wide: "48px"
  brand-gap: "56px"
  panel-gap: "64px"
components:
  button-primary:
    backgroundColor: "{colors.olive}"
    textColor: "{colors.on-primary-light}"
    typography: "{typography.button-label}"
    rounded: "{rounded.control}"
    padding: "16px 24px"
    height: "min 56px"
  button-primary-dark:
    backgroundColor: "{colors.primary-dark}"
    textColor: "{colors.on-primary-dark}"
    typography: "{typography.button-label}"
    rounded: "{rounded.control}"
    padding: "16px 24px"
    height: "min 56px"
  field:
    backgroundColor: "{colors.on-primary-light}"
    textColor: "{colors.coffee}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "20px 16px"
  field-dark:
    backgroundColor: "{colors.field-dark}"
    textColor: "{colors.text-dark}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "20px 16px"
  icon-button:
    size: "min 48px"
  wordmark:
    textColor: "{colors.coffee}"
    typography: "{typography.wordmark}"
  brand-panel:
    backgroundColor: "{colors.coffee}"
    textColor: "{colors.cream}"
    padding: "48px"
---

# Design System: Caféxpress

## Overview

**Creative North Star: "Material Caféxpress"**

La identidad café, crema, oliva y dorado del PDF se expresa mediante controles nativos Material 3. El acceso mantiene una lectura tranquila: marca reconocible, título claro, campos amplios y una acción principal.

Este registro describe el sistema implementado en app_theme.dart y login_screen.dart. Android es la referencia tipográfica y de interacción; el tema conserva las adaptaciones nativas de Flutter en otras plataformas. Los tamaños expresados como px en los tokens corresponden a píxeles lógicos de Flutter.

**Key Characteristics:**
- Identidad cálida con acción oliva y acento dorado.
- Etiquetas persistentes y estados comunicados con texto.
- Superficies planas y contornos legibles.
- Tema claro y oscuro conectado a la preferencia del sistema.

## Colors

La paleta combina la identidad agrícola del producto con los roles semánticos Material.

### Primary
- **Oliva de acción** (olive): acción principal y foco en claro; primary-dark y on-primary-dark forman su pareja en oscuro.
- **Texto de acción claro** (on-primary-light): contenido del botón principal y relleno de campo en claro.

### Secondary
- **Dorado de marca** (gold): símbolo y frase destacada sobre el panel café; también secondary en oscuro.
- **Dorado profundo** (secondary-light): rol secondary del esquema claro.

### Neutral
- **Café** (coffee) y **Crema** (cream): texto/fondo del tema claro; la pareja se invierte en el panel de marca.
- **Superficie y tinta nocturnas** (surface-dark, text-dark): fondo y texto principal en oscuro.
- **Tinta secundaria** (text-muted-light, text-muted-dark): contexto, etiquetas y ayudas.
- **Contorno** (outline-light, outline-dark): límites de campos.
- **Contenedores tonales** (container-light, container-dark) y **campo nocturno** (field-dark): roles de superficie del tema.

Los demás roles, incluidos errorContainer, onErrorContainer y outlineVariant, se heredan de ColorScheme.fromSeed con semilla oliva. No se fijan aquí valores que la aplicación no sobrescribe.

**The Parejas semánticas Rule.** Aplicar juntos los roles de fondo y contenido del tema activo; el panel café conserva su pareja crema/dorado en ambos temas.

## Typography

**Display Font:** tipografía nativa Material; Roboto en Android.
**Body Font:** la misma familia nativa, sin fuente de marca empaquetada.

### Hierarchy
- **Headline**: headlineLarge modificado; títulos de acceso, confirmación y mensaje del panel.
- **Wordmark**: headlineSmall modificado; nombre Caféxpress.
- **Body**: bodyLarge; contexto, campos y confirmación.
- **Body medium**: bodyMedium con interlineado ampliado; texto base heredado.
- **Body small**: bodySmall nativo; cierre al pie.
- **Button label**: labelLarge modificado; acción principal.

La geometría heredada de Material 3 se conserva salvo los overrides presentes en los tokens. El escalado de texto del sistema permanece activo.

**The Jerarquía nativa Rule.** Reutilizar los roles de TextTheme y las modificaciones registradas, manteniendo el comportamiento tipográfico de la plataforma.

## Layout

La pantalla usa SafeArea y contenido desplazable. El bloque de acceso se centra, con ancho máximo de 420 píxeles lógicos; el desplazamiento permite conservar contenido con poco alto, teclado o texto ampliado.

En el acceso actual, el modo expandido requiere simultáneamente ancho de al menos 900 y alto de al menos 500. Distribuye panel de marca y contenido en proporción 5:6. El contenido usa espacio exterior wide en ambos ejes. En modo compacto, coloca la marca sobre el título y usa md horizontal y lg vertical. Estos umbrales describen esta pantalla, no una cuadrícula global.

El ritmo distingue icon-gap para iconos, sm entre título y apoyo, md entre campos, lg antes de la acción y section entre contexto y formulario. Los espacios mayores separan marca, formulario y cierre.

## Elevation & Depth

La composición está plana en reposo: superficies tonales, bordes de campo y un divisor crean separación. No hay sombras personalizadas ni tarjetas elevadas. FilledButton conserva la interacción Material 3: elevación nula en reposo, foco y pulsación, y elevación nativa de 1 en hover. Las capas de estado son las de Flutter.

**The Profundidad nativa Rule.** Mantener la profundidad y las respuestas de estado del componente Material antes de añadir una sombra propia.

## Shapes

Campos, botones y aviso de error comparten la esquina control. Los campos tienen contorno continuo de 1 píxel lógico y foco de 2, coloreado con primary. No se recortan el texto de ayuda ni los mensajes de validación a una sola línea.

## Components

### Buttons
FilledButton ocupa el ancho del formulario, usa la pareja primary/onPrimary y el token button-primary del tema activo. Su altura es mínima y puede crecer con el texto. Durante la solicitud queda deshabilitado, muestra progreso de 20 con trazo de 2 y cambia la etiqueta a «Ingresando…». El icono de avance de 20 se muestra en reposo.

### Inputs / Fields
TextFormField relleno con etiqueta siempre flotante, icono Material y token field del tema activo. El contorno de foco cambia a primary y aumenta de grosor. Los estilos de error y deshabilitado proceden de Material 3; el texto de error admite hasta tres líneas.

El primer campo admite usuario o correo, conserva teclado de texto y avanza a contraseña. El segundo oculta el valor por defecto y ofrece un IconButton con área mínima icon-button y tooltip «Mostrar contraseña»/«Ocultar contraseña». Ambos participan en autocompletado y quedan en solo lectura durante el envío.

### Estado del formulario
El primer envío inválido muestra validación y enfoca el primer campo incorrecto; después se valida al editar. Los fallos de solicitud mantienen los datos y presentan un contenedor tonal errorContainer/onErrorContainer con padding sm y anuncio accesible. La confirmación sustituye al formulario tras recibir una sesión válida y ofrece «Cerrar sesión»; no representa todavía navegación a otra sección.

### Marca y panel
El nombre se acompaña del icono vectorial Material eco_outlined, decorativo para lectores de pantalla. En compacto usa tinta del tema y símbolo primary. El panel expandido mantiene fondo coffee, texto cream y acento gold. Los iconos nativos son parte de este mundo Material; no se usan imágenes raster en la pantalla.

## Do's and Don'ts

### Do:
- **Do** reutilizar ColorScheme y TextTheme del tema activo.
- **Do** conservar etiquetas persistentes, foco visible y nombres accesibles en los controles.
- **Do** permitir desplazamiento y crecimiento vertical con texto ampliado.
- **Do** usar los componentes Material nativos para sus estados de interacción.

### Don't:
- **Don't** fijar una altura que recorte campos, botón o mensajes.
- **Don't** comunicar un fallo únicamente mediante color.
- **Don't** reemplazar los roles de error Material por colores de marca.

La verificación incluye pruebas de widgets y el arranque del formulario en un Moto g56 5G y en el emulador Medium Phone API 37.0. El teclado, el texto ampliado y el tema oscuro se cubren mediante pruebas de widgets; la integración con el backend real sigue pendiente de acordar e implementar su contrato. No se detectaron defectos materiales en la revisión de cierre; no se canoniza ninguna excepción de calidad.
