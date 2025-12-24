import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class L10n {
  const L10n(this.lang);
  final AlignaLanguage lang;

  static L10n of(WidgetRef ref) {
    final lang = ref.watch(languageProvider) ?? AlignaLanguage.en;
    return L10n(lang);
  }

  String get appName => switch (lang) {
    AlignaLanguage.ar => 'ألينا',
    AlignaLanguage.hi => 'अलाइना',
    _ => 'Aligna',
  };

  String get chooseLanguage => switch (lang) {
    AlignaLanguage.ar => 'اختر لغتك',
    AlignaLanguage.hi => 'अपनी भाषा चुनें',
    AlignaLanguage.es => 'Elige tu idioma',
    _ => 'Choose your language',
  };

  String get changeLater => switch (lang) {
    AlignaLanguage.ar => 'يمكنك تغيير هذا لاحقاً.',
    AlignaLanguage.hi => 'आप इसे बाद में बदल सकते हैं।',
    AlignaLanguage.es => 'Puedes cambiarlo más tarde.',
    _ => 'You can change this later.',
  };

  String get howAreYou => switch (lang) {
    AlignaLanguage.ar => 'كيف تشعر اليوم؟',
    AlignaLanguage.hi => 'आज आप कैसे हैं?',
    AlignaLanguage.es => '¿Cómo estás hoy?',
    _ => 'How are you today?',
  };

  String get noRightAnswer => switch (lang) {
    AlignaLanguage.ar => 'لا توجد إجابة صحيحة.',
    AlignaLanguage.hi => 'कोई सही जवाब नहीं है।',
    AlignaLanguage.es => 'No hay una respuesta correcta.',
    _ => 'There’s no right answer.',
  };

  String get shapeGuidance => switch (lang) {
    AlignaLanguage.ar => 'سأشكّل إرشاد اليوم بناءً على ذلك.',
    AlignaLanguage.hi => 'मैं आज की मदद इसी के आधार पर दूँगा।',
    AlignaLanguage.es => 'Adaptaré la guía de hoy según esto.',
    _ => "I’ll shape today’s guidance around this.",
  };

  String get coachTitle => switch (lang) {
    AlignaLanguage.ar => 'مدرب ألينا',
    AlignaLanguage.hi => 'Aligna कोच',
    AlignaLanguage.es => 'Coach Aligna',
    _ => 'Aligna Coach',
  };

  String get askIntention => switch (lang) {
    AlignaLanguage.ar => 'قل لي شيئاً واحداً تريد المزيد منه الآن.',
    AlignaLanguage.hi => 'अभी आप किस चीज़ को और चाहते हैं?',
    AlignaLanguage.es => 'Dime una cosa que quieras más ahora mismo.',
    _ => 'Tell me one thing you want more of right now.',
  };

  String get yourIntention => switch (lang) {
    AlignaLanguage.ar => 'نيّتك',
    AlignaLanguage.hi => 'आपका इरादा',
    AlignaLanguage.es => 'Tu intención',
    _ => 'Your intention',
  };

  String get hintIntention => switch (lang) {
    AlignaLanguage.ar => 'وضوح، ثقة، هدوء، تركيز…',
    AlignaLanguage.hi => 'स्पष्टता, आत्मविश्वास, शांति, फोकस…',
    AlignaLanguage.es => 'Claridad, confianza, calma, enfoque…',
    _ => 'Clarity, confidence, calm, focus…',
  };

  String get continueLabel => switch (lang) {
    AlignaLanguage.ar => 'متابعة',
    AlignaLanguage.hi => 'जारी रखें',
    AlignaLanguage.es => 'Continuar',
    _ => 'Continue',
  };

  String get resetTooltip => switch (lang) {
    AlignaLanguage.ar => 'إعادة ضبط',
    AlignaLanguage.hi => 'रीसेट',
    AlignaLanguage.es => 'Restablecer',
    _ => 'Reset',
  };

  String moodLine(AlignaMood mood) {
    return switch (lang) {
      AlignaLanguage.ar => switch (mood) {
        AlignaMood.calm => 'حسناً. سنجعلها لطيفة وواضحة.',
        AlignaMood.stressed => 'تمام. سنجعلها أخفّ وثابتة.',
        AlignaMood.tired => 'مفهوم. سنقوم بأصغر خطوة مفيدة.',
        AlignaMood.motivated => 'رائع. سنحوّل هذه الطاقة لخطوة واحدة واضحة.',
      },
      AlignaLanguage.hi => switch (mood) {
        AlignaMood.calm => 'ठीक है। इसे सरल और स्पष्ट रखते हैं।',
        AlignaMood.stressed => 'ठीक है। इसे हल्का और स्थिर रखते हैं।',
        AlignaMood.tired => 'समझ गया। आज सबसे छोटी उपयोगी कदम।',
        AlignaMood.motivated => 'बहुत बढ़िया। एक साफ कदम में बदलते हैं।',
      },
      AlignaLanguage.es => switch (mood) {
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
}
