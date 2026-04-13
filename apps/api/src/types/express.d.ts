// Declaration merging: extendemos el tipo Request de Express
// para agregar el campo `user` que el middleware de auth agrega.
//
// Sin esto, TypeScript no sabe que req.user existe y tira error
// en cualquier parte del código donde lo usemos.
//
// El archivo .d.ts (declaration file) le dice a TypeScript
// "este tipo existe así" sin escribir código ejecutable.

declare global {
  namespace Express {
    interface Request {
      // Presente en todos los requests que pasaron por authMiddleware.
      // Opcional (?) porque los endpoints públicos no lo tienen.
      user?: {
        user_id: string;
        tenant_id: string;
        role: string;
      };
    }
  }
}

// Esta línea vacía es necesaria para que TypeScript trate
// este archivo como un módulo y el `declare global` funcione.
export {};
