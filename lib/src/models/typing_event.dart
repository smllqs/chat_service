enum Typing { start, stop }

extension TypeParsing on Typing {
  String value() {
    return toString().split('.').last;
  }

  static Typing fromString(String event) {
    return Typing.values.firstWhere((element) => element.value() == event);
  }
}

class TypingEvent {
  final String from;
  final String to;
  final Typing event;
  late String _id;

  String get id => _id;

  TypingEvent({required this.from, required this.to, required this.event});

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'event': event.value(),
      };

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    final typingEvent = TypingEvent(
      from: json['from'],
      to: json['to'],
      event: TypeParsing.fromString(json['event']),
    );
    typingEvent._id = json['id'];
    return typingEvent;
  }
}
