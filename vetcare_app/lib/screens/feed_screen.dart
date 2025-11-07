// ...existing code...
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo (en la app real vendrán de la API)
    final items = List.generate(8, (i) => {
          'petName': 'Firulais $i',
          'clientName': 'Cliente $i',
          'vetName': 'Dr. Vet $i',
          'service': i % 2 == 0 ? 'Vacunación' : 'Consulta',
          'date': DateTime.now().subtract(Duration(days: i)),
          'image': null,
        });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final it = items[index];
        final dateStr = DateFormat.yMMMd().format(it['date'] as DateTime);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _FeedCard(
            petName: it['petName'] as String,
            clientName: it['clientName'] as String,
            vetName: it['vetName'] as String,
            service: it['service'] as String,
            dateStr: dateStr,
          ),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String petName;
  final String clientName;
  final String vetName;
  final String service;
  final String dateStr;

  const _FeedCard({
    required this.petName,
    required this.clientName,
    required this.vetName,
    required this.service,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(petName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('$service • $dateStr', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(radius: 12, child: const Icon(Icons.person, size: 14)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(clientName, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Veterinario: $vetName', style: theme.textTheme.bodySmall),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

