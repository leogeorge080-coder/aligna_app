enum AlignaMood { fine, stressed, tiredBusy, curious }

extension AlignaMoodKey on AlignaMood {
  /// Keys used inside JSON.
  String get jsonKey => switch (this) {
    AlignaMood.fine => 'fine',
    AlignaMood.stressed => 'stressed',
    AlignaMood.tiredBusy => 'tired_busy',
    AlignaMood.curious => 'curious',
  };
}
