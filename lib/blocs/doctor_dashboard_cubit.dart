import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorDashboardState {
  final bool loading;
  final String? error;
  final int totalCitas;
  final int citasProximas;
  final int totalPacientes;

  const DoctorDashboardState({
    required this.loading,
    required this.error,
    required this.totalCitas,
    required this.citasProximas,
    required this.totalPacientes,
  });

  factory DoctorDashboardState.initial() {
    return const DoctorDashboardState(
      loading: true,
      error: null,
      totalCitas: 0,
      citasProximas: 0,
      totalPacientes: 0,
    );
  }

  DoctorDashboardState copyWith({
    bool? loading,
    String? error,
    int? totalCitas,
    int? citasProximas,
    int? totalPacientes,
  }) {
    return DoctorDashboardState(
      loading: loading ?? this.loading,
      error: error,
      totalCitas: totalCitas ?? this.totalCitas,
      citasProximas: citasProximas ?? this.citasProximas,
      totalPacientes: totalPacientes ?? this.totalPacientes,
    );
  }
}

class DoctorDashboardCubit extends Cubit<DoctorDashboardState> {
  final String medicoId;
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _subscription;

  DoctorDashboardCubit({
    required this.medicoId,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        super(DoctorDashboardState.initial()) {
    _subscribeToCitas();
  }

  void _subscribeToCitas() {
    emit(state.copyWith(loading: true, error: null));

    _subscription = _firestore
        .collection('citas')
        .where('medicoId', isEqualTo: medicoId)
        .snapshots()
        .listen(
      (snapshot) {
        final now = DateTime.now();

        final totalCitas = snapshot.docs.length;

        int citasProximas = 0;
        final Set<String> pacientesUnicos = {};

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['cuando'] as Timestamp?;
          final fecha = ts?.toDate();
          final estado =
              (data['estado'] ?? 'pendiente').toString().toLowerCase();
          // Soporte para ambos campos por si hay citas antiguas
          final pacienteId = (data['pacienteId'] ?? data['userId']) as String?;

          if (pacienteId != null) pacientesUnicos.add(pacienteId);

          if (fecha != null &&
              fecha.isAfter(now) &&
              (estado == 'pendiente' || estado == 'confirmada')) {
            citasProximas++;
          }
        }

        emit(
          state.copyWith(
            loading: false,
            error: null,
            totalCitas: totalCitas,
            citasProximas: citasProximas,
            totalPacientes: pacientesUnicos.length,
          ),
        );
      },
      onError: (e) {
        emit(
          state.copyWith(
            loading: false,
            error: e.toString(),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
