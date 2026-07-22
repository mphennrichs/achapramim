/// Proposta de Preenchimento retornada por POST /api/watches/link-preview.
/// Transitória — nunca criar um Watch a partir dela sem confirmação
/// explícita do usuário no formulário (ver CONTEXT.md e ADR 0003).
class LinkPreviewProposal {
  final String name;
  final int targetPriceCents;
  final List<String> keywords;
  final List<String> blockedWords;
  final bool partialFailure;

  LinkPreviewProposal({
    required this.name,
    required this.targetPriceCents,
    required this.keywords,
    required this.blockedWords,
    required this.partialFailure,
  });

  factory LinkPreviewProposal.fromJson(Map<String, dynamic> json) {
    return LinkPreviewProposal(
      name: json['name'] as String? ?? '',
      targetPriceCents: json['target_price_cents'] as int? ?? 0,
      keywords: (json['keywords'] as List<dynamic>? ?? []).cast<String>(),
      blockedWords:
          (json['blocked_words'] as List<dynamic>? ?? []).cast<String>(),
      partialFailure: json['partial_failure'] as bool? ?? false,
    );
  }
}
