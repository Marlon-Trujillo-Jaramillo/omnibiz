import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventario_app/core/theme.dart';
import 'package:inventario_app/core/isar_provider.dart';
import 'package:inventario_app/models/product_model.dart';
import 'package:inventario_app/models/sale_model.dart';
import 'package:inventario_app/models/customer_model.dart';
import 'package:inventario_app/features/dashboard/dashboard_screen.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    ProductSchema,
    CategorySchema,
    SaleSchema,
    CustomerSchema,
  ], directory: dir.path);

  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const OmniBizApp(),
    ),
  );
}

class OmniBizApp extends ConsumerWidget {
  const OmniBizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color seedColor = Colors.indigo;

    return MaterialApp(
      title: 'OmniBiz Automation',
      debugShowCheckedModeBanner: false,
      theme: OmniTheme.lightTheme(seedColor),
      darkTheme: OmniTheme.darkTheme(seedColor),
      themeMode: ThemeMode.dark,
      home: const BusinessOnboarding(),
    );
  }
}

class BusinessOnboarding extends StatelessWidget {
  const BusinessOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Bienvenido a',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white54,
                ),
              ),
              Text(
                'OmniBiz Automation',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'La solución inteligente para gestionar tu negocio de forma profesional.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const Text(
                'Selecciona tu tipo de negocio:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _BusinessCard(
                      title: 'Tienda de Ropa / Retail',
                      subtitle:
                          'Gestión de tallas, colores y variantes de stock.',
                      icon: Icons.checkroom_rounded,
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const DashboardScreen(businessType: 'retail'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _BusinessCard(
                      title: 'Restaurante / Bar',
                      subtitle: 'Control de mesas, barra e ingredientes.',
                      icon: Icons.restaurant_rounded,
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const DashboardScreen(businessType: 'fnb'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _BusinessCard(
                      title: 'Otro Local Comercial',
                      subtitle: 'Puntos de venta rápidos y servicios.',
                      icon: Icons.store_rounded,
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                const DashboardScreen(businessType: 'generic'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
