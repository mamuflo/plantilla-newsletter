# Documento de Contexto: Generador de Newsletters

## 1. Resumen del Proyecto

Esta es una aplicación de escritorio desarrollada con Flutter cuyo objetivo principal es facilitar la creación de newsletters en formato HTML. La aplicación permite a los usuarios rellenar un formulario con textos, imágenes y vídeos, y genera un fichero HTML final basado en una plantilla predefinida.

## 2. Tecnologías y Componentes Clave

- **Framework:** Flutter
- **Lenguaje:** Dart
- **APIs Externas:**
  - **Google Drive API:** Para subir imágenes y obtener URLs públicas.
  - **YouTube API:** Para subir vídeos.
- **Autenticación:** `google_sign_in` para gestionar el acceso a las APIs de Google.
- **Edición de Texto:** `html_editor_enhanced` para los campos de texto enriquecido (párrafos).
- **Selección de Archivos:** `file_picker` para seleccionar imágenes y vídeos del sistema de archivos local.

## 3. Estructura del Código

El código principal se encuentra en `lib/main.dart` y está estructurado en varios widgets principales:

- **`_HomePageState`**: Es el widget principal que gestiona el estado de toda la aplicación (controladores de texto, datos del usuario, etc.).
- **`_ResourceUploaderCard`**: Un panel centralizado para gestionar la autenticación con Google y la subida de todos los recursos (imágenes a Drive, vídeos a YouTube).
- **`_HeaderBannerCard`**, **`_IntroContentCard`**, etc.: Tarjetas que agrupan diferentes partes del formulario de la newsletter.
- **`_DynamicSectionsManager`**: Permite al usuario añadir o quitar secciones de contenido de forma dinámica.
- **`google_drive_service.dart`**: Clase que encapsula toda la lógica para interactuar con la API de Google Drive (listar carpetas, crear carpetas, subir archivos, hacerlos públicos).
- **`youtube_service.dart`**: Clase que encapsula la lógica para subir vídeos a YouTube.
- **`newsletter_template.html`**: Plantilla HTML base con marcadores de posición (ej: `{{PAGE_TITLE}}`) que se reemplazan al generar la newsletter.

## 4. Flujo de Trabajo Principal

1.  **Autenticación:** El usuario se conecta con su cuenta de Google para dar permisos a la aplicación para acceder a Google Drive y YouTube.
2.  **Configuración de Subida:** El usuario selecciona una carpeta existente en Google Drive o crea una nueva donde se alojarán las imágenes.
3.  **Selección de Recursos:** El usuario selecciona los archivos de imagen y/o vídeo desde su ordenador usando los botones "Seleccionar".
4.  **Subida de Recursos:** El usuario pulsa "Subir Todas las Imágenes Seleccionadas".
    - La aplicación itera sobre los archivos seleccionados.
    - Llama a `google_drive_service.uploadImageAndGetPublicUrl()` por cada imagen.
    - **(Punto de fallo actual)** Este servicio debe subir la imagen a la carpeta seleccionada, cambiar sus permisos para que sea pública y devolver la URL.
    - La URL devuelta se usa para rellenar automáticamente el campo `TextEditingController` correspondiente en el formulario.
5.  **Rellenar Contenido:** El usuario completa el resto de los campos de texto del formulario.
6.  **Generación de HTML:** Al pulsar "Generar Newsletter", la aplicación:
    - Lee el contenido de `newsletter_template.html`.
    - Reemplaza todos los marcadores de posición con el contenido de los controladores del formulario.
    - Muestra una vista previa del HTML final.

## 5. Problema Actual (Bug)

**El problema principal y persistente es que la subida de imágenes a Google Drive no funciona.**

- **Síntoma:** Al pulsar el botón "Subir Todas las Imágenes Seleccionadas", el proceso falla. Recientemente, se ha identificado un error `Null check operator used on a null value`.
- **Causa probable:** El error sugiere que una variable que se espera que no sea nula, lo es en el momento de la ejecución. Las sospechas recaen sobre:
    1.  `selectedFolder`: La carpeta de destino podría no estar seleccionándose o manteniéndose en el estado correctamente.
    2.  `selectedFolder.id`: El ID de la carpeta seleccionada podría ser nulo, aunque la carpeta en sí no lo sea.
    3.  `driveService`: El servicio de Drive podría no estar inicializado correctamente.
    4.  Un problema en la lógica interna de `google_drive_service.dart` al manejar el archivo o los permisos.

- **Comportamiento esperado:** Las imágenes deberían subirse a la carpeta de Drive especificada, y las URLs públicas resultantes deberían rellenar los campos de "URL de la Imagen" en la interfaz.

## 6. Objetivo de la Próxima Intervención

Utilizando este documento como guía, el objetivo es **diagnosticar y corregir el error `Null check operator used on a null value` que ocurre durante la subida de archivos a Google Drive**. Se debe revisar el flujo de datos desde la selección de la carpeta en `_ResourceUploaderCard` hasta la ejecución del método `uploadImageAndGetPublicUrl` en `google_drive_service.dart` para identificar la variable nula.