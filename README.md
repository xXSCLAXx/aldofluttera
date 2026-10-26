# Proyecto Flutter

El proyecto está separado en dos aplicaciones independientes:

- `frontend/`: aplicación Flutter.
- `backend/`: API HTTP en Dart.

## Ejecutar el backend

Desde la raíz:

```powershell
cd backend
dart run
```

El servicio queda disponible en `http://localhost:8080`.

## Ejecutar el frontend

En otra terminal:

```powershell
cd frontend
flutter run
```

La pantalla inicial consulta `GET /api/message` para comprobar la conexión.
Para usar otro puerto del backend, inicia el servicio con `PORT=9090` y
actualiza la URL base en `frontend/lib/services/api_service.dart`.
