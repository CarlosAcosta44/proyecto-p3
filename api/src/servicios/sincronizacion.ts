import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function sincronizarDatos(ultimaSync: Date, cambiosLocales: any[]) {
  const aplicados: string[] = [];
  const conflictos: any[] = [];

  for (const c of cambiosLocales) {
    // updateMany con filtro por versión: si nadie más escribió, cuenta 1.
    const r = await prisma.item.updateMany({
      where: { id: c.id, version: c.version },
      data: { 
        cantidad: c.cantidad, 
        estado: c.estado,
        foto_ruta: c.fotoBase64,
        version: { increment: 1 }, 
        modificadoEn: new Date() 
      },
    });

    if (r.count === 1) { 
      aplicados.push(c.id); 
    } else {
      const actual = await prisma.item.findUnique({ where: { id: c.id } });
      if (actual) {
        conflictos.push({ 
          id: c.id, 
          versionServidor: actual.version,
          versionCliente: c.version,
          valorServidor: { cantidad: actual.cantidad, estado: actual.estado },
          valorCliente: { cantidad: c.cantidad, estado: c.estado } 
        });
      } else {
        // Insert new since it doesn't exist
        const nuevo = await prisma.item.create({
          data: {
            id: c.id,
            codigo_barras: c.codigo_barras || c.id,
            nombre: c.nombre || "Nuevo Item",
            cantidad: c.cantidad,
            estado: c.estado,
            version: 1,
            foto_ruta: c.fotoBase64,
            modificadoEn: new Date()
          }
        });
        aplicados.push(nuevo.id);
      }
    }
  }

  const cambiosRemotos = await prisma.item.findMany({
    where: { modificadoEn: { gt: ultimaSync } },
  });

  return { 
    aplicados, 
    conflictos, 
    cambiosRemotos,
    servidorEn: new Date().toISOString() 
  };
}
