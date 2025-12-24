import '../models/wiring_program.dart';

class WiringContent {
  static const days = <WiringDayContent>[
    WiringDayContent(
      day: 1,
      title: "Clarity begins",
      focus: "We’re not forcing outcomes. We’re clarifying what matters.",
      question: "If today felt 10% better, what would be different?",
      microAction:
          "Write one sentence: “Today I want more ____.” Keep it simple.",
    ),
    WiringDayContent(
      day: 2,
      title: "Name the feeling",
      focus: "Emotions are signals, not obstacles.",
      question: "What feeling are you most trying to protect right now?",
      microAction:
          "Take 60 seconds: breathe slowly and label the feeling in 1–3 words.",
    ),
    WiringDayContent(
      day: 3,
      title: "Identity shift",
      focus: "Small identity statements guide consistent action.",
      question: "Who are you becoming in this season of life?",
      microAction:
          "Finish: “I’m becoming the kind of person who ____.” (one line)",
    ),
    WiringDayContent(
      day: 4,
      title: "Reduce ambiguity",
      focus: "Vague goals create stress. Clarity creates calm.",
      question: "What does “success” mean in plain language today?",
      microAction: "Write one measurable sign for today (even tiny).",
    ),
    WiringDayContent(
      day: 5,
      title: "Aligned action",
      focus: "Action builds belief faster than repeating words.",
      question: "What is one action that matches your intention?",
      microAction:
          "Do a 2-minute starter step (open, draft, search, message, tidy).",
    ),
    // V1: ship with first 7 days, loop with variation; V2: complete all 21 days.
  ];

  static WiringDayContent forDay(int day) {
    final d = day.clamp(1, 21);

    // V1 trick: if you only ship 7 templates, cycle safely.
    final idx = (d - 1) % days.length;
    final base = days[idx];

    return WiringDayContent(
      day: d,
      title: base.title,
      focus: base.focus,
      question: base.question,
      microAction: base.microAction,
    );
  }
}
