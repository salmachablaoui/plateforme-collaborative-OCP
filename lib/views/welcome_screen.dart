import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // URL d'image de fond (tu peux remplacer par ta propre image)
  final String backgroundImage =
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1470&q=80";

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F2),
      body: SafeArea(
        child: isWide ? _buildWebLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  // === Web layout avec background, welcome, boutons, et sections info ===
  Widget _buildWebLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Partie avec image en background, texte et boutons
          Stack(
            children: [
              Container(
                height: 450,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 450,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              SizedBox(
                height: 450,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Bienvenue sur 🌿 OCP Connect",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.3,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black54,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 100.ms),
                        const SizedBox(height: 16),
                        Text(
                          "Une plateforme collaborative moderne qui vous permet de créer un réseau d'amis, partager des publications, interagir, créer des chatrooms, collaborer sur des événements via un calendrier intégré, et bien plus encore.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ).animate().fade(delay: 300.ms),
                        const SizedBox(height: 40),
                        _buildButtons(context, true, isOnImage: true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sections explicatives sous l'image
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Text(
                      "Pourquoi choisir OCP Connect ?",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ).animate().fade(delay: 200.ms),
                    const SizedBox(height: 40),

                    Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      alignment: WrapAlignment.center,
                      children: [
                        _featureCard(
                          icon: Icons.group,
                          title: "Réseau d'amis",
                          description:
                              "Connectez-vous facilement avec vos amis et élargissez votre cercle social.",
                        ),
                        _featureCard(
                          icon: Icons.post_add,
                          title: "Partage de publications",
                          description:
                              "Publiez vos idées, photos et vidéos, et recevez des commentaires en temps réel.",
                        ),
                        _featureCard(
                          icon: Icons.chat_bubble,
                          title: "Chatrooms collaboratives",
                          description:
                              "Discutez en groupe ou en privé avec vos contacts dans des chatrooms dynamiques.",
                        ),
                        _featureCard(
                          icon: Icons.event,
                          title: "Gestion d'événements",
                          description:
                              "Créez et collaborez sur des événements grâce à un calendrier intégré intuitif.",
                        ),
                        _featureCard(
                          icon: Icons.security,
                          title: "Sécurité & confidentialité",
                          description:
                              "Vos données sont protégées avec les meilleures pratiques de sécurité.",
                        ),
                        _featureCard(
                          icon: Icons.mobile_friendly,
                          title: "Accessible partout",
                          description:
                              "Utilisez OCP Connect sur mobile ou desktop avec une expérience fluide.",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer simple
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.green.shade50,
            child: Center(
              child: Text(
                "© 2025 OCP Connect - Tous droits réservés",
                style: TextStyle(color: Colors.green.shade800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Carte de fonctionnalité moderne
  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.6),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.green.shade700),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade800.withOpacity(0.85),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Version mobile simple inchangée
  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.eco,
              size: 90,
              color: Colors.green,
            ).animate().fade().scale(),
            const SizedBox(height: 20),
            Text(
              "OCP Connect",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 10),
            Text(
              "Contrôle intelligent pour un avenir durable.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ).animate().fade(delay: 400.ms),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Connexion"),
            ).animate().slideY(begin: 0.2).fade(),

            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green.shade700),
                padding: const EdgeInsets.symmetric(
                  horizontal: 55,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "S’inscrire",
                style: TextStyle(color: Colors.green),
              ),
            ).animate().slideY(begin: 0.4).fade(),
          ],
        ),
      ),
    );
  }

  // Boutons pour web (ajoute style clair sur image de fond)
  Widget _buildButtons(
    BuildContext context,
    bool isWide, {
    bool isOnImage = false,
  }) {
    final Color primaryColor = isOnImage ? Colors.white : Colors.green.shade800;
    final Color secondaryColor =
        isOnImage ? Colors.white70 : Colors.green.shade800;

    if (isWide) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: Icon(Icons.login, size: 20, color: primaryColor),
              label: Text(
                "Connexion",
                style: TextStyle(fontSize: 18, color: primaryColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isOnImage
                        ? Colors.green.shade600.withOpacity(0.8)
                        : Colors.green.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 14,
              ),
            ).animate().fade().slideY(begin: 0.2),
          ),
          const SizedBox(width: 18),
          Flexible(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              icon: Icon(
                Icons.app_registration,
                size: 20,
                color: secondaryColor,
              ),
              label: Text(
                "S’inscrire",
                style: TextStyle(fontSize: 18, color: secondaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: secondaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ).animate().fade().slideY(begin: 0.4),
          ),
        ],
      );
    } else {
      // Mobile buttons (non utilisé ici, tu peux laisser _buildMobileLayout gérer)
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text("Connexion"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text("S’inscrire"),
          ),
        ],
      );
    }
  }
}
