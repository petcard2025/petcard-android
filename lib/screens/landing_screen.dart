import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color ink = Color(0xFF172033);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _PageWidth(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pets_rounded, color: blue, size: 29),
                          SizedBox(width: 8),
                          Text(
                            'PETCARD',
                            style: TextStyle(
                              color: blue,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Ingresar'),
                        style: TextButton.styleFrom(foregroundColor: blue),
                      ),
                    ],
                  ),
                ),
              ),
              _Hero(
                onRegister: () => Navigator.pushNamed(context, '/registro'),
              ),
              _PageWidth(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Todo lo importante, siempre a mano',
                        style: TextStyle(
                          color: ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Organiza el cuidado de tu mascota con información clara y recordatorios útiles.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _ResponsiveServices(),
                      const SizedBox(height: 48),
                      _CarePanel(
                        onRegister: () =>
                            Navigator.pushNamed(context, '/registro'),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: ink,
                child: const Text(
                  '© 2026 PetCard. Todos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [LandingScreen.blue, LandingScreen.blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: _PageWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 54),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EL BIENESTAR DE TU MASCOTA ES IMPORTANTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Su salud merece un lugar especial.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reúne citas, vacunas, historial médico y recomendaciones de cuidado en un solo perfil.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.9),
                    fontSize: 17,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.pets_rounded),
                  label: const Text('Crear mi cuenta gratis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: LandingScreen.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Empieza a organizar su cuidado en pocos minutos...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveServices extends StatelessWidget {
  const _ResponsiveServices();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        const gap = 16.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: const [
            _ServiceCard(
              icon: Icons.calendar_month_outlined,
              title: 'Citas sin complicaciones',
              description:
              'Agenda visitas y mantén a la vista las próximas consultas de tu mascota.',
              color: LandingScreen.blue,
            ),
            _ServiceCard(
              icon: Icons.vaccines_outlined,
              title: 'Vacunas al día',
              description:
              'Consulta su carnet y recibe recordatorios para no pasar por alto una dosis.',
              color: Color(0xFF059669),
            ),
            _ServiceCard(
              icon: Icons.restaurant_outlined,
              title: 'Mejor alimentación',
              description:
              'Guarda recomendaciones y planes nutricionales pensados para su bienestar.',
              color: Color(0xFF7C3AED),
            ),
          ].map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: LandingScreen.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarePanel extends StatelessWidget {
  const _CarePanel({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final action = ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: LandingScreen.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: const Text(
              'Comenzar ahora',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          final content = const _CareDetails();
          return compact
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [content, const SizedBox(height: 24), action],
          )
              : Row(
            children: [
              const Expanded(child: _CareDetails()),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _CareDetails extends StatelessWidget {
  const _CareDetails();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Una rutina de cuidado más tranquila',
          style: TextStyle(
            color: LandingScreen.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Centraliza la información de cada mascota y consulta lo esencial cuando lo necesites.',
          style: TextStyle(color: Color(0xFF475569), height: 1.45),
        ),
        SizedBox(height: 18),
        _CheckItem('Historial y vacunas en un mismo lugar'),
        SizedBox(height: 10),
        _CheckItem('Recordatorios para próximas citas'),
        SizedBox(height: 10),
        _CheckItem('Información lista para compartir con tu veterinario'),
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: LandingScreen.blue,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF334155))),
        ),
      ],
    );
  }
}

class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}