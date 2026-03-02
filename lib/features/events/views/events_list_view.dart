import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../qr_scanner/views/qr_scanner_view.dart';
import '../../qr_scanner/providers/scan_provider.dart';

class EventsListView extends ConsumerStatefulWidget {
  const EventsListView({super.key});

  @override
  ConsumerState<EventsListView> createState() => _EventsListViewState();
}

class _EventsListViewState extends ConsumerState<EventsListView> {
  @override
  void initState() {
    super.initState();
    // Cargar eventos al iniciar la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFAFE),
      body: RefreshIndicator(
        onRefresh: () => ref.read(eventsProvider.notifier).fetchEvents(),
        color: const Color(0xFFE57700),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Minimalista (Sin Gala Academy arriba)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icono de Bienvenida + Nombre
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('👋', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Text(
                                'Hola ${authState.nombre?.split(' ')[0] ?? "Admin"}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${eventsState.events.length} eventos en total',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE57700),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón Logout al lado del nombre
                    GestureDetector(
                      onTap: () => ref.read(authProvider.notifier).logout(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.power_settings_new_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de Eventos
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: eventsState.isLoading && eventsState.events.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE57700),
                        ),
                      ),
                    )
                  : eventsState.error != null
                  ? SliverToBoxAdapter(
                      child: _buildErrorWidget(eventsState.error!),
                    )
                  : eventsState.events.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyWidget())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildEventItem(eventsState.events[index]),
                        childCount: eventsState.events.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imagen != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.network(
                event.imagen!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 100, color: const Color(0xFFF3F4F6)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Información extra en el Card
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Color(0xFFE57700),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.lugar ?? 'Ubicación no definida',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(event.fecha ?? ""),
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Botón QR (Icono en lugar de palabra SCAN)
                GestureDetector(
                  onTap: () {
                    ref.read(scanProvider.notifier).setEvent(event.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRScannerView()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Color(0xFFE57700),
                      size: 24,
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

  String _formatDate(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);
      final List<String> months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      return '${dt.day} de ${months[dt.month - 1]}, ${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} h';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(eventsProvider.notifier).fetchEvents(),
              child: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF6A6A6A)),
          const SizedBox(height: 16),
          Text(
            'No hay eventos disponibles',
            style: TextStyle(color: Color(0xFF6A6A6A)),
          ),
        ],
      ),
    );
  }
}
