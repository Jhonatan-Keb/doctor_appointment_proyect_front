// lib/screens/my_appointments.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ================= MODELOS =================

class Appointment {
  final String id;
  final DateTime dateTime;
  final DateTime? endTime;
  final String pacienteId;
  final String? medicoId;
  final String motivo;
  final String? lugar;
  final DateTime? createdAt;

  Appointment({
    required this.id,
    required this.dateTime,
    required this.pacienteId,
    required this.motivo,
    this.endTime,
    this.medicoId,
    this.lugar,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'cuando': Timestamp.fromDate(dateTime),
      if (endTime != null) 'cuandoFin': Timestamp.fromDate(endTime!),
      'pacienteId': pacienteId,
      'medicoId': medicoId,
      'motivo': motivo,
      'lugar': lugar,
      'creadoEn':
          createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'titulo': motivo,
    };
  }

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      dateTime: (data['cuando'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['cuandoFin'] as Timestamp?)?.toDate(),
      pacienteId: (data['pacienteId'] ?? '').toString(),
      medicoId: data['medicoId']?.toString(),
      motivo: (data['motivo'] ?? data['titulo'] ?? '').toString(),
      lugar: data['lugar']?.toString(),
      createdAt: (data['creadoEn'] is Timestamp)
          ? (data['creadoEn'] as Timestamp).toDate()
          : null,
    );
  }
}

class DoctorAvailability {
  final String id;
  final String medicoId;
  final DateTime fecha;
  final DateTime horaInicio;
  final DateTime horaFin;
  final bool estaDisponible;

  DoctorAvailability({
    required this.id,
    required this.medicoId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estaDisponible,
  });

  factory DoctorAvailability.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final inicio = (data['horaInicio'] as Timestamp).toDate();
    final fin = (data['horaFin'] as Timestamp?)?.toDate() ?? inicio.add(const Duration(hours: 1));
    return DoctorAvailability(
      id: doc.id,
      medicoId: (data['medicoId'] ?? '').toString(),
      fecha: (data['fecha'] as Timestamp).toDate(),
      horaInicio: inicio,
      horaFin: fin,
      estaDisponible: (data['esta_disponible'] ?? true) as bool,
    );
  }
}

/// ================ PANTALLA =================

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  DateTime? _startDate;
  DateTime? _endDate;

  static const _medicos = <Map<String, String>>[
    {'id': 'dr_lopez', 'nombre': 'Dr. López'},
    {'id': 'dra_martinez', 'nombre': 'Dra. Martínez'},
    {'id': 'dr_ramirez', 'nombre': 'Dr. Ramírez'},
    {'id': 'dra_gomez', 'nombre': 'Dra. Gómez'},
    {'id': 'dr_perez', 'nombre': 'Dr. Pérez'},
    {'id': 'dra_ruiz', 'nombre': 'Dra. Ruiz'},
    {'id': 'dr_castro', 'nombre': 'Dr. Castro'},
  ];
  String? _medicoSeleccionado;
  DateTime? _diaSeleccionado;
  String? _resultadoDia;

  String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtHora(DateTime d) => DateFormat('HH:mm').format(d);
  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  final int _inicioJornada = 8;
  final int _finJornada = 20;
  final bool _inferirSiNoHayCatalogo = true;

  List<DateTime> _generarBloquesDeHora(DateTime day) {
    final base = DateTime(day.year, day.month, day.day);
    final slots = <DateTime>[];
    for (var h = _inicioJornada; h < _finJornada; h++) {
      slots.add(base.add(Duration(hours: h)));
    }
    return slots;
  }

  Query _appointmentsQuery() {
    Query q = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_uid)
        .collection('citas')
        .orderBy('cuando');

    if (_startDate != null) {
      final from = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      q = q.where('cuando', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (_endDate != null) {
      final to = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999);
      q = q.where('cuando', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return q;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _dispDocId(String medicoId, DateTime inicio) {
    final f = DateFormat('yyyyMMdd_HHmm').format(inicio);
    return '${medicoId}_$f';
  }

  Future<void> _deleteWithConfirm(
    BuildContext context, {
    required DocumentReference docRef,
    required String titulo,
    required DateTime? cuando,
    required String? medicoId,
  }) async {
    final fechaTxt =
        cuando == null ? '—' : DateFormat('dd/MM/yyyy – hh:mm a').format(cuando);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: Text('¿Estás seguro de eliminar la cita:\n\n"$titulo"\n$fechaTxt ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // Eliminar de la subcolección del usuario
      await docRef.delete();

      // Eliminar de la colección global de citas
      if (cuando != null && _uid != null) {
        final citasGlobales = await FirebaseFirestore.instance
            .collection('citas')
            .where('pacienteId', isEqualTo: _uid)
            .where('cuando', isEqualTo: Timestamp.fromDate(cuando))
            .get();

        for (final doc in citasGlobales.docs) {
          await doc.reference.delete();
        }

        if (medicoId != null && medicoId.isNotEmpty) {
          final dispId = _dispDocId(medicoId, cuando);
          
          final dispRef = FirebaseFirestore.instance
              .collection('disponibilidad_medicos')
              .doc(dispId);
          
          final dispDoc = await dispRef.get();
          if (dispDoc.exists) {
            await dispRef.update({'esta_disponible': true});
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita eliminada correctamente ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editAppointment(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final tituloCtrl = TextEditingController(text: data['motivo'] ?? '');
    final lugarCtrl = TextEditingController(text: data['lugar'] ?? '');
    
    final tsInicio = data['cuando'] as Timestamp?;
    DateTime? fecha = tsInicio?.toDate();
    TimeOfDay? hora = fecha != null ? TimeOfDay(hour: fecha.hour, minute: fecha.minute) : null;
    String? selMedicoId = data['medicoId']?.toString();

    final fechaOriginal = fecha;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (innerCtx, setSheet) {
                  final fechaTxt = (fecha == null)
                      ? 'Elegir fecha'
                      : DateFormat('dd/MM/yyyy').format(fecha!);
                  final horaTxt = (hora == null)
                      ? 'Elegir hora'
                      : '${hora!.hour.toString().padLeft(2, '0')}:${hora!.minute.toString().padLeft(2, '0')}';

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar cita',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: tituloCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Motivo / Título',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: lugarCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Lugar / Clínica',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selMedicoId,
                          items: _medicos
                              .map((m) => DropdownMenuItem(
                                    value: m['id'],
                                    child: Text(m['nombre']!),
                                  ))
                              .toList(),
                          onChanged: (v) => setSheet(() => selMedicoId = v),
                          decoration: const InputDecoration(
                            labelText: 'Médico',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: innerCtx,
                                    initialDate: fecha ?? now,
                                    firstDate: now,
                                    lastDate: now.add(const Duration(days: 365 * 2)),
                                  );
                                  if (picked != null) {
                                    setSheet(() => fecha = _onlyDate(picked));
                                  }
                                },
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(fechaTxt, style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: innerCtx,
                                    initialTime: hora ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setSheet(() => hora = picked);
                                  }
                                },
                                icon: const Icon(Icons.access_time, size: 18),
                                label: Text(horaTxt, style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final motivo = tituloCtrl.text.trim();
                                  final lugar = lugarCtrl.text.trim();

                                  if (motivo.isEmpty || lugar.isEmpty || selMedicoId == null ||
                                      fecha == null || hora == null) {
                                    ScaffoldMessenger.of(innerCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Completa todos los campos'),
                                      ),
                                    );
                                    return;
                                  }

                                  final DateTime inicio = DateTime(
                                    fecha!.year, fecha!.month, fecha!.day, hora!.hour, hora!.minute,
                                  );
                                  final DateTime fin = inicio.add(const Duration(minutes: 30));

                                  try {
                                    await doc.reference.update({
                                      'motivo': motivo,
                                      'titulo': motivo,
                                      'lugar': lugar,
                                      'medicoId': selMedicoId,
                                      'cuando': Timestamp.fromDate(inicio),
                                      'cuandoFin': Timestamp.fromDate(fin),
                                    });

                                    if (fechaOriginal != null) {
                                      final citasGlobales = await FirebaseFirestore.instance
                                          .collection('citas')
                                          .where('pacienteId', isEqualTo: _uid)
                                          .where('cuando', isEqualTo: Timestamp.fromDate(fechaOriginal))
                                          .get();

                                      for (final citaDoc in citasGlobales.docs) {
                                        await citaDoc.reference.update({
                                          'motivo': motivo,
                                          'lugar': lugar,
                                          'medicoId': selMedicoId,
                                          'cuando': Timestamp.fromDate(inicio),
                                          'cuandoFin': Timestamp.fromDate(fin),
                                        });
                                      }
                                    }

                                    if (innerCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cita actualizada exitosamente ✅'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (innerCtx.mounted) {
                                      ScaffoldMessenger.of(innerCtx).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al actualizar: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Guardar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    tituloCtrl.dispose();
    lugarCtrl.dispose();
  }

  Future<void> _checarDia() async {
    if (_medicoSeleccionado == null || _diaSeleccionado == null) {
      setState(() => _resultadoDia = 'Selecciona médico y fecha.');
      return;
    }
    final fechaSolo = _onlyDate(_diaSeleccionado!);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('disponibilidad_medicos')
          .where('medicoId', isEqualTo: _medicoSeleccionado)
          .where('fecha', isEqualTo: Timestamp.fromDate(fechaSolo))
          .get();

      if (snap.docs.isEmpty) {
        setState(() => _resultadoDia =
            'Sin registros para ${_fmtFecha(fechaSolo)} (se aplicará jornada ${_inicioJornada}:00–${_finJornada}:00).');
        return;
      }

      final anyDisponible = snap.docs.any((d) {
        final m = d.data() as Map<String, dynamic>;
        return (m['esta_disponible'] ?? true) == true;
      });

      setState(() => _resultadoDia =
          anyDisponible ? 'Disponible ese día.' : 'Día ocupado (todos los bloques están tomados).');
    } catch (e) {
      setState(() => _resultadoDia = 'Error al consultar: $e');
    }
  }

  Future<void> _pickDiaDisponibilidad() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _diaSeleccionado ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _diaSeleccionado = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis citas')),
        body: const Center(child: Text('Inicia sesión para ver tus citas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis citas')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate == null ? 'Fecha inicio' : 'Inicio: ${_fmtFecha(_startDate!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _endDate == null ? 'Fecha fin' : 'Fin: ${_fmtFecha(_endDate!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                  )
              ],
            ),
          ),

          const Divider(),

          StreamBuilder<QuerySnapshot>(
            stream: _appointmentsQuery().snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snap.error}'),
                );
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No hay citas en el rango seleccionado.')),
                );
              }

              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final titulo = (data['titulo'] ?? data['motivo'] ?? 'Cita médica').toString();
                  final lugar = (data['lugar'] ?? '—').toString();
                  final medicoId = data['medicoId']?.toString();

                  final tsInicio = data['cuando'] as Timestamp?;
                  final inicio = tsInicio?.toDate();

                  DateTime? fin;
                  if (data['cuandoFin'] is Timestamp) {
                    fin = (data['cuandoFin'] as Timestamp).toDate();
                  } else if (inicio != null) {
                    fin = inicio.add(const Duration(minutes: 30));
                  }

                  final fecha = inicio == null ? '—' : DateFormat('dd/MM/yyyy').format(inicio);
                  final horaInicio = inicio == null ? '—' : DateFormat('HH:mm').format(inicio);
                  final horaFin = fin == null ? '—' : DateFormat('HH:mm').format(fin);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('$fecha  •  $horaInicio - $horaFin  •  $lugar'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editAppointment(context, d),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteWithConfirm(
                              context,
                              docRef: d.reference,
                              titulo: titulo,
                              cuando: inicio,
                              medicoId: medicoId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 25),
          const Divider(thickness: 1),
          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Disponibilidad de médicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _medicos.map((m) {
                final selected = _medicoSeleccionado == m['id'];
                return ChoiceChip(
                  label: Text(m['nombre']!),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _medicoSeleccionado = m['id'];
                    _resultadoDia = null;
                  }),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDiaDisponibilidad,
                    icon: const Icon(Icons.today_outlined),
                    label: Text(
                      _diaSeleccionado == null
                          ? 'Elegir día'
                          : _fmtFecha(_diaSeleccionado!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _checarDia,
                  child: const Text('Checar día'),
                ),
              ],
            ),
          ),

          if (_resultadoDia != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_resultadoDia!,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),

          const SizedBox(height: 10),

          if (_medicoSeleccionado == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Selecciona un médico para ver bloques de disponibilidad.'),
            )
          else if (_diaSeleccionado == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Elige un día para ver la disponibilidad.'),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('disponibilidad_medicos')
                  .where('medicoId', isEqualTo: _medicoSeleccionado)
                  .where('fecha', isEqualTo: Timestamp.fromDate(_onlyDate(_diaSeleccionado!)))
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${snap.error}'),
                  );
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snap.data!.docs;

                final Map<DateTime, bool> estadoPorInicio = {};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final tsInicio = data['horaInicio'] as Timestamp?;
                  if (tsInicio == null) continue;
                  final start = tsInicio.toDate();
                  final disponible = (data['esta_disponible'] ?? true) as bool;
                  estadoPorInicio[start] = disponible;
                }

                final todosLosBloques = _generarBloquesDeHora(_diaSeleccionado!);

                final bool hayCatalogo = docs.isNotEmpty;
                final visibles = <DateTime>[];
                for (final s in todosLosBloques) {
                  final disponibleFlag = estadoPorInicio[s];
                  if (hayCatalogo) {
                    if (disponibleFlag == true) visibles.add(s);
                  } else if (_inferirSiNoHayCatalogo) {
                    if (disponibleFlag != false) visibles.add(s);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibles.isEmpty)
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.event_busy),
                            title: Text('Sin bloques disponibles el ${_fmtFecha(_diaSeleccionado!)}'),
                            subtitle: const Text('Intenta con otro día u otro médico.'),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Disponibles el ${_fmtFecha(_diaSeleccionado!)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: visibles.map((s) {
                                final etiqueta =
                                    '${_fmtHora(s)} - ${_fmtHora(s.add(const Duration(hours: 1)))}';
                                return FilterChip(
                                  selected: false,
                                  label: Text(etiqueta),
                                  avatar: const Icon(Icons.schedule, size: 18),
                                  onSelected: (_) async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Bloque seleccionado: $etiqueta')),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                      if (estadoPorInicio.values.any((v) => v == false))
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ocupados', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: estadoPorInicio.entries
                                    .where((e) => e.value == false)
                                    .map((e) {
                                  final s = e.key;
                                  final etiqueta =
                                      '${_fmtHora(s)} - ${_fmtHora(s.add(const Duration(hours: 1)))}';
                                  return Chip(
                                    label: Text(etiqueta),
                                    avatar: const Icon(Icons.lock_clock, size: 18),
                                    backgroundColor: Colors.grey.shade200,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
