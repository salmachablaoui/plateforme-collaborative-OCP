import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Couleurs OCP modernes
  static const _primaryColor = Color(0xFF2E7D32);
  static const _secondaryColor = Color(0xFF81C784);
  static const _accentColor = Color(0xFF4CAF50);
  static const _darkColor = Color(0xFF1B5E20);
  static const _lightColor = Color(0xFFE8F5E9);
  static const _textColor = Color(0xFF263238);
  static const _whiteColor = Colors.white;

  // Images haute résolution
  final String _heroImage =
      "https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1920&q=80";
  final String _teamImage =
      "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?auto=format&fit=crop&w=1920&q=80";

  // Indicateurs de service
  final List<Map<String, dynamic>> serviceIndicators = [
    {
      'title': "Disponibilité 24/7",
      'description': "Service accessible en permanence",
      'icon': Icons.access_time_filled,
      'color': _accentColor,
    },
    {
      'title': "Support Immédiat",
      'description': "Assistance technique disponible",
      'icon': Icons.support_agent,
      'color': _primaryColor,
    },
    {
      'title': "Sécurité Maximale",
      'description': "Protection avancée des données",
      'icon': Icons.security,
      'color': _secondaryColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;

    return Scaffold(
      backgroundColor: _lightColor,
      body: SafeArea(
        child:
            isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(isTablet, isDesktop),
      ),
    );
  }

  // ========== LAYOUT DESKTOP ==========
  Widget _buildDesktopLayout(bool isTablet, bool isDesktop) {
    return CustomScrollView(
      slivers: [
        // Hero Section
        SliverAppBar(
          expandedHeight: isDesktop ? 700 : 600,
          flexibleSpace: _buildHeroSection(isDesktop),
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
        ),

        // Section Indicateurs
        SliverToBoxAdapter(child: _buildServiceIndicatorsSection(isDesktop)),

        // Section Découverte
        SliverToBoxAdapter(child: _buildDiscoverSection(isTablet, isDesktop)),

        // Section Valeurs
        SliverToBoxAdapter(child: _buildValuesSection(isDesktop)),

        // Footer
        SliverToBoxAdapter(child: _buildModernFooter()),
      ],
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _heroImage,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(color: _darkColor.withOpacity(0.8));
          },
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _darkColor.withOpacity(0.8),
                _darkColor.withOpacity(0.5),
                _darkColor.withOpacity(0.3),
              ],
            ),
          ),
        ),

        Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1000),
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "OCP Connect",
                  style: GoogleFonts.montserrat(
                    fontSize: isDesktop ? 72 : 56,
                    fontWeight: FontWeight.w900,
                    color: _whiteColor,
                    height: 1.1,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                Text(
                  "La plateforme collaborative qui transforme\nvotre façon de travailler",
                  style: GoogleFonts.montserrat(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.w500,
                    color: _whiteColor.withOpacity(0.9),
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                _buildActionButtons(isDesktop),

                const SizedBox(height: 60),

                _buildScrollIndicator(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceIndicatorsSection(bool isDesktop) {
    return Container(
      color: _darkColor,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 80 : 60,
        horizontal: isDesktop ? 80 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1000),
          child: Column(
            children: [
              Text(
                "Nos Engagements",
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 42 : 36,
                  fontWeight: FontWeight.w700,
                  color: _whiteColor,
                ),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: isDesktop ? 40 : 30,
                runSpacing: isDesktop ? 40 : 30,
                children:
                    serviceIndicators.map((indicator) {
                      return _ServiceIndicatorCard(
                        title: indicator['title'],
                        description: indicator['description'],
                        icon: indicator['icon'],
                        color: indicator['color'],
                        isDesktop: isDesktop,
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverSection(bool isTablet, bool isDesktop) {
    return Container(
      color: _whiteColor,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 100 : 80,
        horizontal: isDesktop ? 80 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1000),
          child: Column(
            children: [
              Text(
                "Découvrez OCP Connect",
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 48 : 36,
                  fontWeight: FontWeight.w700,
                  color: _darkColor,
                ),
              ),

              const SizedBox(height: 20),

              Container(width: 100, height: 4, color: _accentColor),

              const SizedBox(height: 60),

              Flex(
                direction: isTablet ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isTablet) ...[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _teamImage,
                          height: isDesktop ? 550 : 450,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureTile(
                          icon: Icons.groups,
                          title: "Réseau Professionnel",
                          description:
                              "Connectez-vous avec vos collaborateurs OCP",
                          isDesktop: isDesktop,
                        ),

                        const SizedBox(height: 30),

                        _FeatureTile(
                          icon: Icons.workspaces,
                          title: "Collaboration en Temps Réel",
                          description: "Partagez et créez vos propres contenus",
                          isDesktop: isDesktop,
                        ),

                        const SizedBox(height: 30),

                        _FeatureTile(
                          icon: Icons.insights,
                          title: "Analytique Avancée",
                          description:
                              "Suivez vos interactions professionnelles",
                          isDesktop: isDesktop,
                        ),

                        const SizedBox(height: 50),

                        _buildActionButtons(isDesktop),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValuesSection(bool isDesktop) {
    return Container(
      color: _lightColor,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 100 : 80,
        horizontal: isDesktop ? 80 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : 1000),
          child: Column(
            children: [
              Text(
                "Nos Valeurs",
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 48 : 36,
                  fontWeight: FontWeight.w700,
                  color: _darkColor,
                ),
              ),

              const SizedBox(height: 20),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 30,
                  childAspectRatio: isDesktop ? 1 : 1.3,
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final values = [
                    {
                      'title': "Innovation Continue",
                      'description':
                          "Nous repoussons les limites technologiques",
                      'icon': Icons.auto_awesome,
                      'color': _accentColor,
                    },
                    {
                      'title': "Collaboration Ouverte",
                      'description': "Travailler ensemble sans frontières",
                      'icon': Icons.handshake,
                      'color': _primaryColor,
                    },
                    {
                      'title': "Excellence Opérationnelle",
                      'description': "Qualité et fiabilité à chaque étape",
                      'icon': Icons.star,
                      'color': _secondaryColor,
                    },
                  ];
                  return _ValueCard(
                    title: values[index]['title'] as String,
                    description: values[index]['description'] as String,
                    icon: values[index]['icon'] as IconData,
                    color: values[index]['color'] as Color,
                    isDesktop: isDesktop,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      color: _darkColor,
      child: Center(
        child: Column(
          children: [
            // Logo textuel stylisé
            Text(
              "OCP CONNECT",
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _whiteColor,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 20),

            // Ligne décorative
            Container(width: 150, height: 2, color: _accentColor),

            const SizedBox(height: 30),

            // Texte descriptif
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "La plateforme collaborative officielle du Groupe OCP",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: _whiteColor.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Copyright
            Text(
              "© ${DateTime.now().year} OCP Group - Tous droits réservés",
              style: GoogleFonts.montserrat(
                color: _whiteColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Scrollable.ensureVisible(
                context,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutQuart,
              );
            },
            child: Column(
              children: [
                Text(
                  "Explorer la plateforme",
                  style: GoogleFonts.montserrat(
                    color: _whiteColor.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.expand_more,
                  color: _whiteColor.withOpacity(0.9),
                  size: 36,
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: 10, duration: 1000.ms);
  }

  Widget _buildActionButtons(bool isDesktop) {
    return Wrap(
      spacing: 20,
      runSpacing: 15,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: _whiteColor,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 30,
              vertical: isDesktop ? 18 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login, size: 22),
              const SizedBox(width: 10),
              Text(
                "Se connecter",
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _whiteColor, width: 2),
            foregroundColor: _whiteColor,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 30,
              vertical: isDesktop ? 18 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.app_registration, size: 22),
              const SizedBox(width: 10),
              Text(
                "Créer un compte",
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.4),
      ],
    );
  }

  // ========== MOBILE LAYOUT ==========
  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                Icon(
                  Icons.connected_tv,
                  size: 80,
                  color: _primaryColor,
                ).animate().fadeIn().scale(),

                const SizedBox(height: 30),

                Text(
                  "OCP Connect",
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 15),

                Text(
                  "La plateforme collaborative du groupe OCP",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: _textColor.withOpacity(0.7),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 50),

                _buildMobileButtons(),

                const Spacer(flex: 2),

                // Footer mobile simplifié
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Text(
                        "OCP CONNECT",
                        style: GoogleFonts.montserrat(
                          color: _textColor.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "© ${DateTime.now().year}",
                        style: TextStyle(
                          color: _textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: _whiteColor,
            minimumSize: const Size(220, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5,
          ),
          child: const Text("Se connecter"),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

        const SizedBox(height: 15),

        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _accentColor, width: 2),
            foregroundColor: _accentColor,
            minimumSize: const Size(220, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text("Créer un compte"),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.4),
      ],
    );
  }
}

class _ServiceIndicatorCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDesktop;

  const _ServiceIndicatorCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDesktop ? 300 : 250,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: _WelcomeScreenState._whiteColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.montserrat(
              fontSize: isDesktop ? 16 : 14,
              color: _WelcomeScreenState._whiteColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDesktop;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isDesktop ? 60 : 50,
          height: isDesktop ? 60 : 50,
          decoration: BoxDecoration(
            color: _WelcomeScreenState._accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: isDesktop ? 32 : 28,
            color: _WelcomeScreenState._accentColor,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 22 : 20,
                  fontWeight: FontWeight.w600,
                  color: _WelcomeScreenState._darkColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 17 : 16,
                  color: _WelcomeScreenState._textColor.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDesktop;

  const _ValueCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 40 : 30),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 100 : 80,
            height: isDesktop ? 100 : 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: isDesktop ? 48 : 40, color: color),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: isDesktop ? 26 : 24,
              fontWeight: FontWeight.w700,
              color: _WelcomeScreenState._darkColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            description,
            style: GoogleFonts.montserrat(
              fontSize: isDesktop ? 18 : 16,
              color: _WelcomeScreenState._textColor.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
