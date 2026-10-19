# Inicio de sesión

## Alcance

Modo Operate. Un único formulario para acceder mediante usuario o correo y
contraseña. Registro, roles, recuperación de contraseña y dashboard quedan fuera
de este paso. La confirmación de acceso aparece solo tras una respuesta válida.

## Direction contract

THESIS: Un acceso claro con identidad Caféxpress; la tarea ocupa el centro de la
pantalla y no compite con contenido promocional.

OWN-WORLD: Superficie crema, texto café, acción verde oliva, acento dorado. Material
3, etiquetas persistentes, campos amplios y una sola acción principal.

STORY: El usuario reconoce la marca, escribe usuario o correo y contraseña, envía
el formulario y entiende el estado de la solicitud sin perder sus datos al fallar.

FIRST VIEWPORT: En móvil, marca y contexto arriba, título y formulario debajo; en
pantallas amplias, panel de marca café a la izquierda y formulario de ancho
limitado a la derecha. El botón queda después de los campos; hay desplazamiento
cuando aparece el teclado o aumenta el tamaño de texto.

FORM: Formulario nativo Material 3; composición acotada al acceso solicitado,
heredando la referencia del PDF. No requiere selección de otra identidad visual.

FINISH: Interfaz revisada, sistema visual documentado en DESIGN.md, pruebas de
widgets aprobadas y arranque comprobado en un teléfono Android y en un emulador.
La integración con el backend real sigue pendiente de definir su contrato.

## Decisiones abiertas

El endpoint y los JSON deben acordarse con backend. No se asume persistencia de
sesión ni navegación por rol en este paso. La verificación visual debe indicar
si se realizó con renderizado de pruebas de Flutter o en un dispositivo.
