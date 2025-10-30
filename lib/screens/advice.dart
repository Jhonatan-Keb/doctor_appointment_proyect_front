import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HealthTipsPage extends StatefulWidget {
  const HealthTipsPage({super.key});

  @override
  State<HealthTipsPage> createState() => _HealthTipsPageState();
}

class _TipsScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class _HealthTipsPageState extends State<HealthTipsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Todos';
  final Set<String> _favorites = {};

  late final List<HealthTip> _tips;
  late final HealthTip _tipOfDay;

  final List<String> _categories = const [
    'Todos',
    'Dolor de cabeza',
    'Garganta y tos',
    'Fiebre leve',
    'Estómago',
    'Resfriado',
    'Sueño y estrés',
    'Hidratación',
  ];

  @override
  void initState() {
    super.initState();
    _tips = _seedTips();
    _tipOfDay =
        _tips[(DateTime.now().day + DateTime.now().month) % _tips.length];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HealthTip> _seedTips() {
    return [
      // --- Dolor de cabeza ---
      HealthTip(
        id: 'dc1',
        title: 'Compresas frías en frente/cuello',
        summary: 'Alivia migraña o tensión leve.',
        details:
            'Aplica una compresa fría 10–15 min en frente/nuque. Descansa en un lugar oscuro y silencioso.',
        category: 'Dolor de cabeza',
        icon: Icons.ac_unit_rounded,
        color: const Color(0xFF3B82F6),
      ),
      HealthTip(
        id: 'dc2',
        title: 'Hidratación suficiente',
        summary: 'La deshidratación causa cefalea.',
        details:
            'Bebe agua de forma regular; añade electrolitos si sudaste mucho o hiciste ejercicio.',
        category: 'Dolor de cabeza',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF06B6D4),
      ),
      HealthTip(
        id: 'dc3',
        title: 'Descanso breve y estiramientos',
        summary: 'Para cefalea por pantallas/estrés.',
        details:
            'Cierra ojos 5 min, relaja mandíbula y cuello; estira trapecios y hombros.',
        category: 'Dolor de cabeza',
        icon: Icons.self_improvement_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      HealthTip(
        id: 'dc4',
        title: 'Cafeína moderada',
        summary: 'Puede ayudar a algunos tipos.',
        details:
            'Una taza de café/té puede aliviar, pero evita exceso o tarde por la noche.',
        category: 'Dolor de cabeza',
        icon: Icons.coffee_rounded,
        color: const Color(0xFF92400E),
      ),
      HealthTip(
        id: 'dc5',
        title: 'Evita gatillos comunes',
        summary: 'Luz intensa, olores, ayuno.',
        details:
            'Usa lentes de sol, ventila espacios y procura comer a horas regulares.',
        category: 'Dolor de cabeza',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFF59E0B),
      ),
      HealthTip(
        id: 'dc6',
        title: 'Respiración 4-7-8',
        summary: 'Baja tensión muscular.',
        details:
            'Inhala 4s, mantén 7s, exhala 8s. Repite 4 rondas para calmar el sistema nervioso.',
        category: 'Dolor de cabeza',
        icon: Icons.air_rounded,
        color: const Color(0xFF14B8A6),
      ),

      // --- Garganta y tos ---
      HealthTip(
        id: 'gt1',
        title: 'Miel con limón tibio',
        summary: 'Calma irritación y suaviza la tos.',
        details:
            'Mezcla miel con limón en agua tibia. No dar miel a menores de 1 año.',
        category: 'Garganta y tos',
        icon: Icons.local_drink_rounded,
        color: const Color(0xFFF59E0B),
      ),
      HealthTip(
        id: 'gt2',
        title: 'Gárgaras con agua salina',
        summary: 'Desinflama y limpia la garganta.',
        details:
            'Disuelve 1/2 cdita de sal en un vaso de agua tibia. Haz gárgaras 15–30s, 2–3 veces/día.',
        category: 'Garganta y tos',
        icon: Icons.bubble_chart_rounded,
        color: const Color(0xFF06B6D4),
      ),
      HealthTip(
        id: 'gt3',
        title: 'Humidificador / vapor',
        summary: 'Mejora sequedad y congestión.',
        details:
            'Usa humidificador o ducha tibia; el vapor suaviza vías respiratorias.',
        category: 'Garganta y tos',
        icon: Icons.cloud_rounded,
        color: const Color(0xFF64748B),
      ),
      HealthTip(
        id: 'gt4',
        title: 'Evita irritantes',
        summary: 'Tabaco, polvo, aire muy frío.',
        details:
            'Ventila, usa mascarilla en polvo/frío y evita humo de segunda mano.',
        category: 'Garganta y tos',
        icon: Icons.smoke_free_rounded,
        color: const Color(0xFFEF4444),
      ),
      HealthTip(
        id: 'gt5',
        title: 'Caramelos sin azúcar',
        summary: 'Estimulan saliva protectora.',
        details:
            'Dulces/mentolados sin azúcar o pastillas de própolis pueden aliviar.',
        category: 'Garganta y tos',
        icon: Icons.medication_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      HealthTip(
        id: 'gt6',
        title: 'Hidratación constante',
        summary: 'Tibios mejor que helados.',
        details:
            'Agua, tés, caldos. Evita bebidas muy frías si aumentan la tos.',
        category: 'Garganta y tos',
        icon: Icons.local_cafe_rounded,
        color: const Color(0xFF92400E),
      ),

      // --- Fiebre leve ---
      HealthTip(
        id: 'fl1',
        title: 'Ropa ligera y ambiente fresco',
        summary: 'Ayuda a regular temperatura.',
        details:
            'Evita abrigarte en exceso. Habitación ventilada y fresca favorece el confort.',
        category: 'Fiebre leve',
        icon: Icons.thermostat_rounded,
        color: const Color(0xFFEF4444),
      ),
      HealthTip(
        id: 'fl2',
        title: 'Beber líquidos frecuentemente',
        summary: 'Evita deshidratación.',
        details:
            'Agua, sueros orales, caldos. Bebe en sorbos si hay náusea.',
        category: 'Fiebre leve',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF06B6D4),
      ),
      HealthTip(
        id: 'fl3',
        title: 'Descanso y poca actividad',
        summary: 'Apoya al sistema inmune.',
        details:
            'Limita ejercicio/esfuerzo. Duerme si tu cuerpo lo pide.',
        category: 'Fiebre leve',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      HealthTip(
        id: 'fl4',
        title: 'Paños tibios en frente/axilas',
        summary: 'Confort sintomático.',
        details:
            'Paños tibios (no fríos) 5–10 min; evita escalofríos.',
        category: 'Fiebre leve',
        icon: Icons.spa_rounded,
        color: const Color(0xFF14B8A6),
      ),
      HealthTip(
        id: 'fl5',
        title: 'Comidas suaves y ligeras',
        summary: 'Fáciles de digerir.',
        details:
            'Sopas, purés, frutas suaves. Evita fritos/grasas.',
        category: 'Fiebre leve',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFF59E0B),
      ),
      HealthTip(
        id: 'fl6',
        title: 'Señales de alarma',
        summary: 'Consulta si persiste o sube demasiado.',
        details:
            'Dolor intenso, rigidez de cuello, confusión, sarpullido, deshidratación: busca atención médica.',
        category: 'Fiebre leve',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
      ),

      // --- Estómago ---
      HealthTip(
        id: 'es1',
        title: 'Dieta BRAT (si te va bien)',
        summary: 'Banana, arroz, puré manzana, tostadas.',
        details:
            'Útil en molestias leves/diarrea. No es para uso prolongado; reintroduce alimentos gradualmente.',
        category: 'Estómago',
        icon: Icons.rice_bowl_rounded,
        color: const Color(0xFFF59E0B),
      ),
      HealthTip(
        id: 'es2',
        title: 'Jengibre / manzanilla',
        summary: 'Calman náuseas leves.',
        details:
            'Infusión tibia de jengibre o manzanilla; sorbos lentos.',
        category: 'Estómago',
        icon: Icons.local_cafe_rounded,
        color: const Color(0xFF92400E),
      ),
      HealthTip(
        id: 'es3',
        title: 'Evita grasas/picantes/álcohol',
        summary: 'Irritan la mucosa gástrica.',
        details:
            'Prefiere cocción simple (hervido, plancha) y raciones pequeñas.',
        category: 'Estómago',
        icon: Icons.no_food_rounded,
        color: const Color(0xFFEF4444),
      ),
      HealthTip(
        id: 'es4',
        title: 'Hidratación con electrolitos',
        summary: 'Clave si hay diarrea.',
        details:
            'Sueros orales o bebidas con electrolitos para reponer pérdidas.',
        category: 'Estómago',
        icon: Icons.science_rounded,
        color: const Color(0xFF06B6D4),
      ),
      HealthTip(
        id: 'es5',
        title: 'Come despacio, porciones pequeñas',
        summary: 'Evita sobrecargar el estómago.',
        details:
            'Comidas frecuentes y pequeñas mejor que pocas y abundantes.',
        category: 'Estómago',
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFF10B981),
      ),
      HealthTip(
        id: 'es6',
        title: 'Consulta si hay alarma',
        summary: 'Dolor severo, sangre, fiebre alta.',
        details:
            'Vómitos persistentes, deshidratación, sangre en heces, dolor intenso: acude a urgencias.',
        category: 'Estómago',
        icon: Icons.health_and_safety_rounded,
        color: const Color(0xFFDC2626),
      ),

      // --- Resfriado ---
      HealthTip(
        id: 're1',
        title: 'Inhalaciones de vapor',
        summary: 'Descongestiona vías aéreas.',
        details:
            'Vapor de agua con toalla sobre cabeza 5–10 min; opcional eucalipto.',
        category: 'Resfriado',
        icon: Icons.cloud_rounded,
        color: const Color(0xFF64748B),
      ),
      HealthTip(
        id: 're2',
        title: 'Sopas/caldos tibios',
        summary: 'Hidratación + minerales.',
        details:
            'Caldo de pollo/verduras reconforta y aporta líquidos.',
        category: 'Resfriado',
        icon: Icons.soup_kitchen_rounded,
        color: const Color(0xFFF59E0B),
      ),
      HealthTip(
        id: 're3',
        title: 'Limpieza nasal suave',
        summary: 'Solución salina.',
        details:
            'Spray o irrigación nasal con solución salina ayuda a quitar mucosidad.',
        category: 'Resfriado',
        icon: Icons.masks_rounded,
        color: const Color(0xFF06B6D4),
      ),
      HealthTip(
        id: 're4',
        title: 'Descanso y poco esfuerzo',
        summary: 'Apoya la recuperación.',
        details:
            'Duerme lo suficiente y escucha a tu cuerpo.',
        category: 'Resfriado',
        icon: Icons.hotel_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      HealthTip(
        id: 're5',
        title: 'Bebidas calientes',
        summary: 'Miel/limón, té, infusiones.',
        details:
            'Alivian garganta y ayudan con la hidratación.',
        category: 'Resfriado',
        icon: Icons.local_cafe_rounded,
        color: const Color(0xFF92400E),
      ),
      HealthTip(
        id: 're6',
        title: 'Ventilar y evitar humo',
        summary: 'Mejora el aire.',
        details:
            'Ambientes ventilados y libres de humo de tabaco.',
        category: 'Resfriado',
        icon: Icons.air_rounded,
        color: const Color(0xFF14B8A6),
      ),

      // --- Sueño y estrés ---
      HealthTip(
        id: 'se1',
        title: 'Horarios regulares',
        summary: 'Ritmo circadiano estable.',
        details:
            'Acuéstate/levántate a la misma hora todos los días.',
        category: 'Sueño y estrés',
        icon: Icons.schedule_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      HealthTip(
        id: 'se2',
        title: 'Apaga pantallas 60 min antes',
        summary: 'Menos luz azul = más melatonina.',
        details:
            'Lee, medita o estírate en ese periodo previo.',
        category: 'Sueño y estrés',
        icon: Icons.nightlight_round,
        color: const Color(0xFF3B82F6),
      ),
      HealthTip(
        id: 'se3',
        title: 'Respiración 4-7-8',
        summary: 'Baja ansiedad.',
        details:
            'Inhala 4s, retén 7s, exhala 8s; 4 rondas.',
        category: 'Sueño y estrés',
        icon: Icons.spa_rounded,
        color: const Color(0xFF14B8A6),
      ),
      HealthTip(
        id: 'se4',
        title: 'Rutina relajante',
        summary: 'Señales al cerebro.',
        details:
            'Ducha tibia, lectura suave, journaling de 5 min.',
        category: 'Sueño y estrés',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF92400E),
      ),
      HealthTip(
        id: 'se5',
        title: 'Exposición a luz de mañana',
        summary: 'Refuerza el reloj biológico.',
        details:
            '10–15 min de luz natural temprano.',
        category: 'Sueño y estrés',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFF59E0B),
      ),
      HealthTip(
        id: 'se6',
        title: 'Actividad física moderada',
        summary: 'Mejora calidad del sueño.',
        details:
            'Caminar 30 min/día; evita ejercicio intenso muy tarde.',
        category: 'Sueño y estrés',
        icon: Icons.directions_walk_rounded,
        color: const Color(0xFF10B981),
      ),

      // --- Hidratación ---
      HealthTip(
        id: 'hi1',
        title: '6–8 vasos/día (ajusta)',
        summary: 'Más si hace calor o haces ejercicio.',
        details:
            'Usa botella reutilizable y bebe a lo largo del día.',
        category: 'Hidratación',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF06B6D4),
      ),
      HealthTip(
        id: 'hi2',
        title: 'Observa el color de orina',
        summary: 'Claro = buena hidratación.',
        details:
            'Amarillo oscuro puede indicar que te falta agua.',
        category: 'Hidratación',
        icon: Icons.opacity_rounded,
        color: const Color(0xFF3B82F6),
      ),
      HealthTip(
        id: 'hi3',
        title: 'Sopas, frutas, infusiones',
        summary: 'También hidratan.',
        details:
            'Sandía, melón, pepino, caldos e infusiones cuentan.',
        category: 'Hidratación',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFF10B981),
      ),
      HealthTip(
        id: 'hi4',
        title: 'Limita azucaradas/alcohol',
        summary: 'Deshidratan/añaden calorías.',
        details:
            'Prefiere agua, té sin azúcar y café moderado.',
        category: 'Hidratación',
        icon: Icons.no_drinks_rounded,
        color: const Color(0xFFEF4444),
      ),
      HealthTip(
        id: 'hi5',
        title: 'Recordatorios de agua',
        summary: 'Apps/alarma/posits.',
        details:
            'Programa avisos para beber regularmente.',
        category: 'Hidratación',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      HealthTip(
        id: 'hi6',
        title: 'Electrolitos si sudas mucho',
        summary: 'Repón sales/minerales.',
        details:
            'Útil en deporte o clima caluroso; evita exceso de azúcar.',
        category: 'Hidratación',
        icon: Icons.science_rounded,
        color: const Color(0xFFF59E0B),
      ),
    ];
  }

  List<HealthTip> get _filtered {
    return _tips.where((t) {
      final byCategory = _selectedCategory == 'Todos' || t.category == _selectedCategory;
      final byQuery = _query.isEmpty ||
          t.title.toLowerCase().contains(_query) ||
          t.summary.toLowerCase().contains(_query) ||
          t.details.toLowerCase().contains(_query);
      return byCategory && byQuery;
    }).toList();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  void _showTipDetail(HealthTip tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tip.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tip.icon, size: 28, color: tip.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: _favorites.contains(tip.id)
                        ? 'Quitar de favoritos'
                        : 'Agregar a favoritos',
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleFavorite(tip.id);
                    },
                    icon: Icon(
                      _favorites.contains(tip.id)
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _favorites.contains(tip.id) ? tip.color : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tip.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(tip.details, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Consejos para síntomas leves. Si empeoran o persisten, consulta a un profesional.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consejos de Salud'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Consejo del día
          _TipOfDayCard(
            tip: _tipOfDay,
            onTap: () => _showTipDetail(_tipOfDay),
            isFavorite: _favorites.contains(_tipOfDay.id),
            onFav: () => _toggleFavorite(_tipOfDay.id),
          ),
          const SizedBox(height: 20),

          // Buscador
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar consejos...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),

          // Categorías
          ScrollConfiguration(
            behavior: _TipsScrollBehavior(),
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de consejos
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin resultados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prueba con otra búsqueda o categoría',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((t) {
              final fav = _favorites.contains(t.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showTipDetail(t),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: t.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(t.icon, color: t.color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.summary,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: fav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                          icon: Icon(
                            fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: fav ? t.color : null,
                          ),
                          onPressed: () => _toggleFavorite(t.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recomendaciones generales para síntomas leves. No sustituyen evaluación médica.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====== MODELO ======
class HealthTip {
  final String id;
  final String title;
  final String summary;
  final String details;
  final String category;
  final IconData icon;
  final Color color;

  const HealthTip({
    required this.id,
    required this.title,
    required this.summary,
    required this.details,
    required this.category,
    required this.icon,
    required this.color,
  });
}

// ====== WIDGET: Consejo del día ======
class _TipOfDayCard extends StatelessWidget {
  final HealthTip tip;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFav;

  const _TipOfDayCard({
    required this.tip,
    required this.onTap,
    required this.isFavorite,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shadowColor: tip.color.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tip.color.withOpacity(0.15),
                tip.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tip.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(tip.icon, size: 32, color: tip.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tip.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CONSEJO DEL DÍA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tip.color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                icon: Icon(
                  isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isFavorite ? tip.color : null,
                ),
                onPressed: onFav,
              ),
            ],
          ),
        ),
      ),
    );
  }
}