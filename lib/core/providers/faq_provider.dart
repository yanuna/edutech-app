import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// A Help & Support FAQ entry.
class Faq {
  final String question;
  final String answer;
  final String? category;
  const Faq({required this.question, required this.answer, this.category});

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        question: json['question']?.toString() ?? '',
        answer: json['answer']?.toString() ?? '',
        category: json['category']?.toString(),
      );
}

final faqsProvider = FutureProvider<List<Faq>>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.faqs);
  return ((res.data['faqs'] as List?) ?? const [])
      .map((e) => Faq.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});
