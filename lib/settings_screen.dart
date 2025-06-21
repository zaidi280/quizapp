import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme_manager.dart';
import 'utlis/global.color.dart';
import 'widgets/theme_toggle_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GlobalColor.getGradientColors(context),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 30),
                _buildThemeSection(context),
                const SizedBox(height: 20),
                _buildAppInfoSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GlobalColor.getCardBackgroundColor(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: GlobalColor.getShadowColor(context),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: GlobalColor.mainColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paramètres',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GlobalColor.mainColor,
                  ),
                ),
                Text(
                  'Personnalisez votre expérience',
                  style: TextStyle(
                    fontSize: 14,
                    color: GlobalColor.getTextSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GlobalColor.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GlobalColor.getShadowColor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: GlobalColor.mainColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Apparence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlobalColor.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Theme toggle options
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choisissez votre thème préféré',
                  style: TextStyle(
                    fontSize: 14,
                    color: GlobalColor.getTextSecondaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Theme toggle buttons
          const Center(
            child: ThemeToggleButton(
              lightText: 'Clair',
              darkText: 'Sombre',
              isCompact: false,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Theme switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GlobalColor.mainColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GlobalColor.mainColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.brightness_6,
                  color: GlobalColor.mainColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Basculer automatiquement',
                    style: TextStyle(
                      fontSize: 14,
                      color: GlobalColor.getTextPrimaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const ThemeToggleSwitch(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GlobalColor.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GlobalColor.getShadowColor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: GlobalColor.mainColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'À propos de l\'application',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlobalColor.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoItem(
            context,
            'Version',
            '1.0.0',
            Icons.tag,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            'Développeur',
            'QuizDS Team',
            Icons.code,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            'Thème',
            'Mode Sombre/Clair',
            Icons.dark_mode,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: GlobalColor.getTextSecondaryColor(context),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: GlobalColor.getTextSecondaryColor(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: GlobalColor.getTextPrimaryColor(context),
          ),
        ),
      ],
    );
  }
}
