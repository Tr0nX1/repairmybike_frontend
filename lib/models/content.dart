class CarouselItem {
  final int id;
  final String title;
  final String? subtitle;
  final String image;
  final String? actionLink;
  final int order;

  CarouselItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.image,
    this.actionLink,
    required this.order,
  });

  factory CarouselItem.fromJson(Map<String, dynamic> json) {
    return CarouselItem(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      image: json['image'],
      actionLink: json['action_link'],
      order: json['order'],
    );
  }
}

enum SupportType { call, email, whatsapp, website }

class SupportOption {
  final int id;
  final String title;
  final SupportType type;
  final String value;
  final String? iconImage;
  final String? bgColor;
  final int order;

  SupportOption({
    required this.id,
    required this.title,
    required this.type,
    required this.value,
    this.iconImage,
    this.bgColor,
    required this.order,
  });

  factory SupportOption.fromJson(Map<String, dynamic> json) {
    return SupportOption(
      id: json['id'],
      title: json['title'],
      type: _parseType(json['option_type']),
      value: json['value'],
      iconImage: json['icon_image'],
      bgColor: json['bg_color'],
      order: json['order'],
    );
  }

  static SupportType _parseType(String? t) {
    switch (t) {
      case 'call': return SupportType.call;
      case 'email': return SupportType.email;
      case 'whatsapp': return SupportType.whatsapp;
      case 'website': return SupportType.website;
      default: return SupportType.website;
    }
  }
}
