import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';

class PhrasesScreen extends StatelessWidget {
  const PhrasesScreen({super.key});

  static final List<Map<String, dynamic>> categories = [
    {
      'title': 'Emergencias',
      'icon': Icons.emergency,
      'color': Colors.redAccent,
      'phrases': [
        {'es': 'Necesito ayuda', 'en': 'I need help'},
        {'es': 'Llama a la policía', 'en': 'Call the police'},
        {'es': 'Necesito un médico', 'en': 'I need a doctor'},
        {'es': 'Estoy perdido', 'en': 'I am lost'},
        {'es': 'Es una emergencia', 'en': 'This is an emergency'},
      ],
    },
    {
      'title': 'Trabajo',
      'icon': Icons.work,
      'color': Colors.blueAccent,
      'phrases': [
        {'es': 'Estoy buscando trabajo', 'en': 'I am looking for a job'},
        {'es': '¿Cuánto pagan por hora?', 'en': 'How much do you pay per hour?'},
        {'es': 'Puedo empezar mañana', 'en': 'I can start tomorrow'},
        {'es': 'Tengo experiencia en construcción', 'en': 'I have experience in construction'},
        {'es': '¿Necesitan trabajadores?', 'en': 'Do you need workers?'},
      ],
    },
    {
      'title': 'Compras y Comida',
      'icon': Icons.shopping_cart,
      'color': Colors.greenAccent,
      'phrases': [
        {'es': '¿Cuánto cuesta?', 'en': 'How much does it cost?'},
        {'es': 'Quiero esto', 'en': 'I want this'},
        {'es': 'La cuenta por favor', 'en': 'The check please'},
        {'es': '¿Aceptan efectivo?', 'en': 'Do you accept cash?'},
        {'es': 'No como carne', 'en': 'I do not eat meat'},
      ],
    },
    {
      'title': 'Transporte',
      'icon': Icons.directions_bus,
      'color': Colors.orangeAccent,
      'phrases': [
        {'es': '¿Dónde está la parada del autobús?', 'en': 'Where is the bus stop?'},
        {'es': '¿Cuánto cuesta el boleto?', 'en': 'How much is the ticket?'},
        {'es': 'Lléveme a esta dirección', 'en': 'Take me to this address'},
        {'es': '¿A qué hora sale?', 'en': 'What time does it leave?'},
        {'es': 'Estoy bajando aquí', 'en': 'I am getting off here'},
      ],
    },
    {
      'title': 'Vivienda',
      'icon': Icons.home,
      'color': Colors.purpleAccent,
      'phrases': [
        {'es': 'Busco un cuarto para rentar', 'en': 'I am looking for a room to rent'},
        {'es': '¿Cuánto es la renta mensual?', 'en': 'How much is the monthly rent?'},
        {'es': '¿Incluye servicios?', 'en': 'Does it include utilities?'},
        {'es': '¿Puedo verlo hoy?', 'en': 'Can I see it today?'},
        {'es': 'Necesito un depósito', 'en': 'I need a deposit'},
      ],
    },
    {
      'title': 'Saludos y Básicos',
      'icon': Icons.waving_hand,
      'color': Colors.tealAccent,
      'phrases': [
        {'es': 'Hola, buenos días', 'en': 'Hello, good morning'},
        {'es': 'Gracias', 'en': 'Thank you'},
        {'es': 'Por favor', 'en': 'Please'},
        {'es': 'No hablo inglés muy bien', 'en': 'I do not speak English very well'},
        {'es': '¿Habla español?', 'en': 'Do you speak Spanish?'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(category: category);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        leading: Icon(category['icon'], color: category['color']),
        title: Text(
          category['title'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: (category['phrases'] as List).map((phrase) {
          return _PhraseTile(
            spanish: phrase['es'],
            english: phrase['en'],
          );
        }).toList(),
      ),
    );
  }
}

class _PhraseTile extends StatelessWidget {
  final String spanish;
  final String english;

  const _PhraseTile({required this.spanish, required this.english});

  @override
  Widget build(BuildContext context) {
    final speech = context.read<SpeechService>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spanish, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  english,
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.lightBlueAccent, size: 22),
                onPressed: () => speech.speak(english, language: 'en-US'),
                tooltip: 'Escuchar',
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: english));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copiado'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
