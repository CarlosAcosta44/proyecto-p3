import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventario_estado_provider.dart';
import 'escaner_pagina.dart';
import '../../dominio/servicios/sincronizacion_servicio.dart';
import 'conflictos_dialogo.dart';

class InicioPagina extends ConsumerWidget {
  const InicioPagina({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(inventarioProvider);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Inventario CEET', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: estado.cargando ? null : () async {
              try {
                final exito = await ref.read(inventarioProvider.notifier).sincronizar();
                if (context.mounted) {
                  if (exito) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sincronización exitosa')),
                    );
                  } else {
                    final error = ref.read(inventarioProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al sincronizar: $error'), backgroundColor: Colors.red),
                    );
                  }
                }
              } on ConflictosException catch(e) {
                if (context.mounted) {
                  mostrarDialogoConflicto(context, ref, e.conflictos);
                }
              }
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)],
          ),
        ),
        child: estado.cargando 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF39A900)))
            : estado.items.isEmpty 
                ? const Center(child: Text('El inventario está vacío. Escanea o sincroniza.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 100, bottom: 100, left: 16, right: 16),
                    itemCount: estado.items.length,
                    itemBuilder: (context, index) {
                      final item = estado.items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Cód: ${item.codigoBarras} | Cant: ${item.cantidad}\nEstado: ${item.estado}'),
                          isThreeLine: true,
                          trailing: item.sucio == 1 
                              ? const Icon(Icons.cloud_upload_outlined, color: Colors.amber)
                              : const Icon(Icons.check_circle_outline, color: Color(0xFF39A900)),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF39A900),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EscanerPagina()));
        },
      ),
    );
  }
}
