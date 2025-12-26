import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class L10n {
  const L10n(this.lang);
  final String lang;

  static L10n of(WidgetRef ref) {
    final lang = ref.watch(languageProvider) ?? 'en';
    return L10n(lang);
  }

  String get appName => switch (lang) {
    'ar' => 'ألينا',
    'hi' => 'अलाइना',
    _ => 'Aligna',
  };

  String get chooseLanguage => switch (lang) {
    'ar' => 'اختر لغتك',
    'hi' => 'अपनी भाषा चुनें',
    'es' => 'Elige tu idioma',
    _ => 'Choose your language',
  };

  String get changeLater => switch (lang) {
    'ar' => 'يمكنك تغيير هذا لاحقاً.',
    'hi' => 'आप इसे बाद में बदल सकते हैं।',
    'es' => 'Puedes cambiarlo más tarde.',
    _ => 'You can change this later.',
  };

  String get howAreYou => switch (lang) {
    'ar' => 'كيف تشعر اليوم؟',
    'hi' => 'आज आप कैसे हैं?',
    'es' => '¿Cómo estás hoy?',
    _ => 'How are you today?',
  };

  String get noRightAnswer => switch (lang) {
    'ar' => 'لا توجد إجابة صحيحة.',
    'hi' => 'कोई सही जवाब नहीं है।',
    'es' => 'No hay una respuesta correcta.',
    _ => 'There\'s no right answer.',
  };

  String get shapeGuidance => switch (lang) {
    'ar' => 'سأشكّل إرشاد اليوم بناءً على ذلك.',
    'hi' => 'मैं आज की मदद इसी के आधार पर दूँगा।',
    'es' => 'Adaptaré la guía de hoy según esto.',
    _ => "I'll shape today's guidance around this.",
  };

  String get coachTitle => switch (lang) {
    'ar' => 'مدرب ألينا',
    'hi' => 'Aligna कोच',
    'es' => 'Coach Aligna',
    _ => 'Aligna Coach',
  };

  String get askIntention => switch (lang) {
    'ar' => 'قل لي شيئاً واحداً تريد المزيد منه الآن.',
    'hi' => 'अभी आप किस चीज़ को और चाहते हैं?',
    'es' => 'Dime una cosa que quieras más ahora mismo.',
    _ => 'Tell me one thing you want more of right now.',
  };

  String get yourIntention => switch (lang) {
    'ar' => 'نيّتك',
    'hi' => 'आपका इरादा',
    'es' => 'Tu intención',
    _ => 'Your intention',
  };

  String get hintIntention => switch (lang) {
    'ar' => 'وضوح، ثقة، هدوء، تركيز…',
    'hi' => 'स्पष्टता, आत्मविश्वास, शांति, फोकस…',
    'es' => 'Claridad, confianza, calma, enfoque…',
    _ => 'Clarity, confidence, calm, focus…',
  };

  String get continueLabel => switch (lang) {
    'ar' => 'متابعة',
    'hi' => 'जारी रखें',
    'es' => 'Continuar',
    _ => 'Continue',
  };

  String get resetTooltip => switch (lang) {
    'ar' => 'إعادة ضبط',
    'hi' => 'रीसेट',
    'es' => 'Restablecer',
    _ => 'Reset',
  };

  String moodLine(AlignaMood mood) {
    return switch (lang) {
      'ar' => switch (mood) {
        AlignaMood.calm => 'حسناً. سنجعلها لطيفة وواضحة.',
        AlignaMood.stressed => 'تمام. سنجعلها أخفّ وثابتة.',
        AlignaMood.tired => 'مفهوم. سنقوم بأصغر خطوة مفيدة.',
        AlignaMood.motivated => 'رائع. سنحوّل هذه الطاقة لخطوة واحدة واضحة.',
      },
      'hi' => switch (mood) {
        AlignaMood.calm => 'ठीक है। इसे सरल और स्पष्ट रखते हैं।',
        AlignaMood.stressed => 'ठीक है। इसे हल्का और स्थिर रखते हैं।',
        AlignaMood.tired => 'समझ गया। आज सबसे छोटी उपयोगी कदम।',
        AlignaMood.motivated => 'बहुत बढ़िया। एक साफ कदम में बदलते हैं।',
      },
      'es' => switch (mood) {
        AlignaMood.calm => 'Bien. Lo haremos suave y claro.',
        AlignaMood.stressed => 'De acuerdo. Lo haremos más ligero y estable.',
        AlignaMood.tired => 'Entendido. Haremos el paso más pequeño y útil.',
        AlignaMood.motivated =>
          'Genial. Convertiremos esa energía en un paso claro.',
      },
      _ => switch (mood) {
        AlignaMood.calm => "Good. We'll keep this gentle and clear.",
        AlignaMood.stressed => "Okay. We'll make this lighter and steady.",
        AlignaMood.tired => "Understood. We'll do the smallest useful step.",
        AlignaMood.motivated =>
          "Great. We'll turn that energy into one clean step.",
      },
    };
  }

  String get journalSaved => switch (lang) {
    'ar' => 'تم حفظ المذكرة',
    'hi' => 'दैनिकी सहेजी गई',
    'es' => 'Diario guardado',
    _ => 'Journal saved',
  };

  String get writeYourThoughts => switch (lang) {
    'ar' => 'اكتب أفكارك...',
    'hi' => 'अपने विचार लिखें...',
    'es' => 'Escribe tus pensamientos...',
    _ => 'Write your thoughts...',
  };

  String get skip => switch (lang) {
    'ar' => 'تخطي',
    'hi' => 'छोड़ें',
    'es' => 'Omitir',
    _ => 'Skip',
  };

  String get saveReflection => switch (lang) {
    'ar' => 'احفظ التأمل',
    'hi' => 'अनुभव सहेजें',
    'es' => 'Guardar reflexión',
    _ => 'Save Reflection',
  };
}
