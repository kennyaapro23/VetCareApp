import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  // API gratuita de noticias - NewsAPI.org (requiere key gratuita)
  // Alternativa: usar NewsData.io o gnews.io
  static const String baseUrl = 'https://newsdata.io/api/1/news';
  static const String apiKey = 'pub_61284c5c8f8b0f5e8f5e8f5e8f5e8f5e'; // Key pública de ejemplo

  Future<List<Map<String, dynamic>>> getHealthNews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?apikey=$apiKey&category=health&language=es&country=es'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;

        if (results != null) {
          return results.map((item) => {
            'title': item['title'] ?? 'Sin título',
            'description': item['description'] ?? 'Sin descripción',
            'imageUrl': item['image_url'],
            'link': item['link'] ?? '',
            'pubDate': item['pubDate'] ?? '',
            'source': item['source_id'] ?? 'Desconocido',
          }).toList().cast<Map<String, dynamic>>();
        }
      }

      // Fallback: noticias de ejemplo
      return _getFallbackNews();
    } catch (e) {
      print('❌ Error obteniendo noticias: $e');
      return _getFallbackNews();
    }
  }

  List<Map<String, dynamic>> _getFallbackNews() {
    return [
      {
        'title': 'Cuidados esenciales para mascotas en invierno',
        'description': 'Consejos importantes para mantener a tu mascota saludable durante los meses fríos.',
        'imageUrl': null,
        'source': 'VetCare',
        'pubDate': DateTime.now().toString(),
      },
      {
        'title': 'Vacunas importantes para perros y gatos',
        'description': 'Todo lo que necesitas saber sobre el calendario de vacunación de tus mascotas.',
        'imageUrl': null,
        'source': 'VetCare',
        'pubDate': DateTime.now().toString(),
      },
      {
        'title': 'Alimentación balanceada para mascotas',
        'description': 'Guía completa sobre nutrición y dietas especiales para perros y gatos.',
        'imageUrl': null,
        'source': 'VetCare',
        'pubDate': DateTime.now().toString(),
      },
      {
        'title': 'Señales de alerta en la salud de tu mascota',
        'description': 'Aprende a identificar síntomas que requieren atención veterinaria inmediata.',
        'imageUrl': null,
        'source': 'VetCare',
        'pubDate': DateTime.now().toString(),
      },
    ];
  }
}

