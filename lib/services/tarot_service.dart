import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TarotCard {
  final String id;
  final String cardName;
  final String imageUrl;
  final String aiInsight;
  final String? trackType;

  const TarotCard({
    required this.id,
    required this.cardName,
    required this.imageUrl,
    required this.aiInsight,
    this.trackType,
  });

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      id: (json['id'] as String?) ?? '',
      cardName: (json['card_name'] as String?) ?? 'Unknown',
      imageUrl: (json['image_url'] as String?) ?? '',
      aiInsight: (json['ai_insight'] as String?) ?? '',
      trackType: json['track_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'card_name': cardName,
    'image_url': imageUrl,
    'ai_insight': aiInsight,
    'track_type': trackType,
  };
}

class TarotService {
  static final _supabase = Supabase.instance.client;

  static Future<TarotCard?> getDailyCard({String? trackType}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    final tsKey = 'aligna_daily_tarot_ts_$userId';
    final cardKey = 'aligna_daily_tarot_card_$userId';

    final lastTs = prefs.getInt(tsKey);
    final cachedJson = prefs.getString(cardKey);
    if (lastTs != null && cachedJson != null) {
      final ageMs = DateTime.now().millisecondsSinceEpoch - lastTs;
      if (ageMs < const Duration(hours: 24).inMilliseconds) {
        final decoded = json.decode(cachedJson);
        if (decoded is Map<String, dynamic>) {
          return TarotCard.fromJson(decoded);
        }
      }
    }

    try {
      List<dynamic> response;
      if (trackType != null && trackType.trim().isNotEmpty) {
        response = await _supabase
            .from('tarot_cards')
            .select('*')
            .eq('track_type', trackType)
            .limit(200);
        if (response.isEmpty) {
          response = await _supabase.from('tarot_cards').select('*').limit(200);
        }
      } else {
        response = await _supabase.from('tarot_cards').select('*').limit(200);
      }

      if (response.isEmpty) {
        if (kDebugMode) {
          debugPrint('[TarotService] tarot_cards table is empty.');
        }
        return null;
      }

      final randomIndex = Random().nextInt(response.length);
      final card = TarotCard.fromJson(
        Map<String, dynamic>.from(response[randomIndex] as Map),
      );
      if (card.id.isEmpty || card.imageUrl.isEmpty) {
        if (kDebugMode) {
          debugPrint('[TarotService] Invalid card payload: ${card.toJson()}');
        }
        return null;
      }

      await prefs.setInt(
        tsKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setString(cardKey, json.encode(card.toJson()));

      return card;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TarotService] Failed to fetch tarot card: $e');
      }
      // Fall back to cached card if present
      if (cachedJson != null) {
        final decoded = json.decode(cachedJson);
        if (decoded is Map<String, dynamic>) {
          return TarotCard.fromJson(decoded);
        }
      }
      return null;
    }
  }
}
