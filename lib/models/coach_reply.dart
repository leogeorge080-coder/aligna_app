class CoachReply {
  final String message;
  final String? microAction;
  final String? closure;

  const CoachReply({required this.message, this.microAction, this.closure});

  factory CoachReply.fromJson(Map<String, dynamic> json) {
    // Support both flat and nested "data" payloads.
    final root = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : json;

    final msg = (root['message'] ?? '').toString().trim();
    if (msg.isEmpty) {
      // If backend returns an error shape, surface something readable.
      final err = (root['error'] ?? json['error'] ?? '').toString().trim();
      throw Exception(
        err.isNotEmpty ? err : 'Invalid response: missing message',
      );
    }

    return CoachReply(
      message: msg,
      microAction: (root['micro_action'] ?? root['microAction'])?.toString(),
      closure: (root['closure'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (microAction != null) 'micro_action': microAction,
      if (closure != null) 'closure': closure,
    };
  }
}
