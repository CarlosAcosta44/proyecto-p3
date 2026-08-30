# Proyecto 3: Inventario CEET sin conexión

Este repositorio contiene la solución al Proyecto 3 (P3) del CEET, el cual consiste en un aplicativo de inventario resiliente a ambientes sin red, con bloqueo optimista y soporte local en SQLite.

## Estructura
- `/api`: Backend en Node.js, Express y Prisma, conectado a PostgreSQL en Neon.
- `/app`: Aplicativo móvil en Flutter y Riverpod, con SQLite y escáner nativo de la cámara (mobile_scanner).
- `/docs`: Documentación y justificaciones de decisiones técnicas (`decisiones.md`).

## Instrucciones de Ejecución

### 1. Ejecutar Backend
```bash
cd api
npm install
npm run dev # requiere ts-node-dev o similar
```

### 2. Ejecutar Aplicativo Móvil
```bash
cd app
flutter pub get
flutter run
```
