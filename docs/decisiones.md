# Decisiones Técnicas - Proyecto 3

## 1. Umbral de compresión de imágenes
Se decidió utilizar la biblioteca `flutter_image_compress` configurando una calidad del 70% y resoluciones máximas de 800x800. Tras realizar pruebas con la cámara del dispositivo físico, el tamaño original de la captura (que promedia de 2 a 4 MB) se logra comprimir a un tamaño consistentemente inferior a los **300 KB**. 
Esta decisión nos permite enviar la imagen directamente en formato `Base64` como parte del payload JSON, lo que simplifica la transacción y garantiza atomicidad sin requerir uploads asíncronos mediante `multipart/form-data`.

## 2. Resolución de Conflictos (Bloqueo Optimista)
En cuanto a la sincronización bidireccional, se utilizó un enfoque de bloqueo optimista basado en un campo numérico `version`.
- Si dos usuarios descargan el inventario (versión 1) y el usuario A sube un cambio primero, su registro queda en versión 2.
- Cuando el usuario B intenta subir su versión 1, el servidor la rechaza (conflictos).
- En el cliente, el conflicto no se resuelve de manera silenciosa: se despliega un diálogo que le muestra al usuario sus valores locales contra los valores del servidor. 
- Si el usuario decide **conservar lo local**, la app reemplaza la versión en disputa por la versión que tiene el servidor y lo reenvía en el siguiente ciclo, obligando a que gane.

## 3. Modo de Conteo y Escáner Continuo
Para mejorar la usabilidad durante inventarios extensos, el escáner (a través de `mobile_scanner`) opera en modo `noDuplicates`, evitando lectura en bucle del mismo código. Además, para los códigos que no existan en el sistema, la app vibra (`HapticFeedback.vibrate()`) durante el escaneo, proporcionando retroalimentación sin bloquear la vista.
