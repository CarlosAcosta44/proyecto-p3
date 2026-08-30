import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventario_estado_provider.dart';
import '../../dominio/entidades/item.dart';

void mostrarDialogoConflicto(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> conflictos) {
  if (conflictos.isEmpty) return;
  
  final conflicto = conflictos.first;
  final id = conflicto['id'];
  
  final items = ref.read(inventarioProvider).items;
  final itemLocal = items.firstWhere(
    (i) => i.id == id, 
    orElse: () => Item(id: id, codigoBarras: '?', nombre: 'Desconocido', cantidad: 0, estado: '', version: 0)
  );

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Conflicto de Versión', style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El ítem "${itemLocal.nombre}" fue modificado por otro usuario. Elige qué versión conservar:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TUS CAMBIOS (Local)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Cantidad: ${conflicto['valorCliente']['cantidad']}'),
                  Text('Estado: ${conflicto['valorCliente']['estado']}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CAMBIOS EN RED (Remoto)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Cantidad: ${conflicto['valorServidor']['cantidad']}'),
                  Text('Estado: ${conflicto['valorServidor']['estado']}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final ganador = itemLocal.copiarCon(
                cantidad: conflicto['valorServidor']['cantidad'],
                estado: conflicto['valorServidor']['estado'],
                version: conflicto['versionServidor'],
                sucio: 0,
              );
              await ref.read(inventarioProvider.notifier).resolverConflicto(ganador);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Descartar los míos'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39A900), foregroundColor: Colors.white),
            onPressed: () async {
              final ganador = itemLocal.copiarCon(
                cantidad: conflicto['valorCliente']['cantidad'],
                estado: conflicto['valorCliente']['estado'],
                version: conflicto['versionServidor'],
                sucio: 1, 
              );
              await ref.read(inventarioProvider.notifier).resolverConflicto(ganador);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Forzar mis cambios'),
          ),
        ],
      );
    }
  );
}
