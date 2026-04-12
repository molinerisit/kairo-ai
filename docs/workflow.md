# Workflow de Desarrollo — Kairo AI

## Flujo completo de una tarea

```
1. Issue en GitHub  →  2. Branch  →  3. Desarrollo  →  4. Commit  →  5. PR  →  6. Merge
```

### Paso a paso

**1. Crear el issue (ticket de tarea)**
- Ir a GitHub → Issues → New Issue
- Título: acción + módulo + descripción corta
- Agregar: descripción, criterios de aceptación, label, milestone (sprint)

**2. Crear el branch (rama de código)**
```bash
git checkout main
git pull origin main
git checkout -b feature/KAI-01-auth-registro
```

Convención de nombres:
```
feature/KAI-{numero}-{descripcion-corta}   # nueva funcionalidad
fix/KAI-{numero}-{descripcion-corta}       # corrección de bug
chore/KAI-{numero}-{descripcion-corta}     # infraestructura, config
docs/KAI-{numero}-{descripcion-corta}      # solo documentación
```

**3. Desarrollar**
- Una sola tarea por branch
- Commits chicos y frecuentes
- Si aparece algo nuevo, crear un issue nuevo — no mezclarlo

**4. Hacer commits con mensajes semánticos**
```bash
git add src/modules/auth/
git commit -m "feat(auth): add user registration endpoint with JWT"
```

Tipos de commit:
```
feat     → nueva funcionalidad
fix      → corrección de bug
chore    → configuración, dependencias, sin cambio funcional
refactor → reestructuración sin cambio de comportamiento
test     → agregar o modificar tests
docs     → solo documentación
style    → formato, espacios, punto y coma (sin cambio lógico)
```

**5. Abrir el PR (Pull Request — solicitud de fusión de código)**
- Push al branch: `git push origin feature/KAI-01-auth-registro`
- Abrir PR en GitHub contra `main`
- Completar el template (descripción, checklist, cómo probar)
- Linkear el issue: escribir `Closes #1` en la descripción

**6. Merge a main**
- Revisar el PR (aunque seas solo vos, tomarte 5 minutos)
- Hacer merge usando **Squash and merge** para mantener el historial limpio
- El branch se cierra automáticamente
- El issue se cierra automáticamente si usaste `Closes #`

---

## Estructura de branches

```
main           # producción — código estable, siempre deployable
  └── feature/ # desarrollo de funcionalidades
  └── fix/     # correcciones
  └── chore/   # infraestructura
```

Reglas:
- Nunca commitear directo a `main`
- Cada branch sale desde `main` actualizado
- Un branch = una tarea = un PR

---

## Convención de issues en GitHub

### Título
```
[MÓDULO] Acción corta
[AUTH] Crear endpoint de registro
[TABLE] Implementar edición inline de filas
[CONV] Vista lista de conversaciones
```

### Labels (etiquetas)
```
feature      → nueva funcionalidad
bug          → algo roto
chore        → infraestructura / config
sprint-1     → pertenece al Sprint 1
sprint-2     → pertenece al Sprint 2
blocked      → bloqueado por dependencia
```

### Criterios de aceptación
Cada issue debe tener al menos 2-3 criterios concretos:
```
- El usuario puede registrarse con email y password
- Se devuelve un JWT válido firmado con el tenant_id
- Si el email ya existe, se retorna error 409 con mensaje claro
```

---

## CI/CD (Integración Continua / Despliegue Continuo)

Al hacer push a cualquier branch:
- Se corren los linters (analizadores de estilo de código)
- Se corren los tests

Al hacer merge a `main`:
- Se corre el pipeline completo
- Se hace deploy automático al entorno de staging (ambiente de prueba)

---

## Entornos

| Entorno | Branch | Descripción |
|---|---|---|
| Local | cualquiera | Máquina del desarrollador |
| Staging | main | Ambiente de prueba pre-producción |
| Production | tag/release | Ambiente real con usuarios reales |

---

## Variables de entorno

Nunca commitear credenciales. Usar:
- `.env` para desarrollo local (está en .gitignore)
- Variables de entorno del servidor para staging y producción

Archivo de ejemplo en el repo: `.env.example` (sin valores reales).
