class SocialLinks {
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? youtube;
  final String? linkedin;
  final String? tiktok;
  final String? snapchat;
  final String? pinterest;
  final String? tripadvisor;
  final String? bookingDotCom;
  final String? expedia;
  final String? airbnb;
  final String? website;
  final String? eventbrite;
  final String? meetup;
  final String? whatsapp;
  final String? telegram;
  final String? wechat;

  const SocialLinks({
    this.facebook,
    this.twitter,
    this.instagram,
    this.youtube,
    this.linkedin,
    this.tiktok,
    this.snapchat,
    this.pinterest,
    this.tripadvisor,
    this.bookingDotCom,
    this.expedia,
    this.airbnb,
    this.website,
    this.eventbrite,
    this.meetup,
    this.whatsapp,
    this.telegram,
    this.wechat,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (facebook != null) map['facebook'] = facebook;
    if (twitter != null) map['twitter'] = twitter;
    if (instagram != null) map['instagram'] = instagram;
    if (youtube != null) map['youtube'] = youtube;
    if (linkedin != null) map['linkedin'] = linkedin;
    if (tiktok != null) map['tiktok'] = tiktok;
    if (snapchat != null) map['snapchat'] = snapchat;
    if (pinterest != null) map['pinterest'] = pinterest;
    if (tripadvisor != null) map['tripadvisor'] = tripadvisor;
    if (bookingDotCom != null) map['bookingDotCom'] = bookingDotCom;
    if (expedia != null) map['expedia'] = expedia;
    if (airbnb != null) map['airbnb'] = airbnb;
    if (website != null) map['website'] = website;
    if (eventbrite != null) map['eventbrite'] = eventbrite;
    if (meetup != null) map['meetup'] = meetup;
    if (whatsapp != null) map['whatsapp'] = whatsapp;
    if (telegram != null) map['telegram'] = telegram;
    if (wechat != null) map['wechat'] = wechat;
    return map;
  }

  factory SocialLinks.fromJson(Map<String, dynamic> data) {
    return SocialLinks(
      facebook: data['facebook'] as String?,
      twitter: data['twitter'] as String?,
      instagram: data['instagram'] as String?,
      youtube: data['youtube'] as String?,
      linkedin: data['linkedin'] as String?,
      tiktok: data['tiktok'] as String?,
      snapchat: data['snapchat'] as String?,
      pinterest: data['pinterest'] as String?,
      tripadvisor: data['tripadvisor'] as String?,
      bookingDotCom: data['bookingDotCom'] as String?,
      expedia: data['expedia'] as String?,
      airbnb: data['airbnb'] as String?,
      website: data['website'] as String?,
      eventbrite: data['eventbrite'] as String?,
      meetup: data['meetup'] as String?,
      whatsapp: data['whatsapp'] as String?,
      telegram: data['telegram'] as String?,
      wechat: data['wechat'] as String?,
    );
  }

  SocialLinks copyWith({
    String? facebook,
    String? twitter,
    String? instagram,
    String? youtube,
    String? linkedin,
    String? tiktok,
    String? snapchat,
    String? pinterest,
    String? tripadvisor,
    String? bookingDotCom,
    String? expedia,
    String? airbnb,
    String? website,
    String? eventbrite,
    String? meetup,
    String? whatsapp,
    String? telegram,
    String? wechat,
  }) {
    return SocialLinks(
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      linkedin: linkedin ?? this.linkedin,
      tiktok: tiktok ?? this.tiktok,
      snapchat: snapchat ?? this.snapchat,
      pinterest: pinterest ?? this.pinterest,
      tripadvisor: tripadvisor ?? this.tripadvisor,
      bookingDotCom: bookingDotCom ?? this.bookingDotCom,
      expedia: expedia ?? this.expedia,
      airbnb: airbnb ?? this.airbnb,
      website: website ?? this.website,
      eventbrite: eventbrite ?? this.eventbrite,
      meetup: meetup ?? this.meetup,
      whatsapp: whatsapp ?? this.whatsapp,
      telegram: telegram ?? this.telegram,
      wechat: wechat ?? this.wechat,
    );
  }

  List<Map<String, String>> get activeLinks {
    final links = <Map<String, String>>[];
    if (facebook != null) links.add({'platform': 'Facebook', 'url': facebook!});
    if (twitter != null) links.add({'platform': 'Twitter', 'url': twitter!});
    if (instagram != null) {
      links.add({'platform': 'Instagram', 'url': instagram!});
    }
    if (youtube != null) links.add({'platform': 'YouTube', 'url': youtube!});
    if (linkedin != null) links.add({'platform': 'LinkedIn', 'url': linkedin!});
    if (tiktok != null) links.add({'platform': 'TikTok', 'url': tiktok!});
    if (snapchat != null) links.add({'platform': 'Snapchat', 'url': snapchat!});
    if (pinterest != null) {
      links.add({'platform': 'Pinterest', 'url': pinterest!});
    }
    if (tripadvisor != null) {
      links.add({'platform': 'TripAdvisor', 'url': tripadvisor!});
    }
    if (bookingDotCom != null) {
      links.add({'platform': 'Booking.com', 'url': bookingDotCom!});
    }
    if (expedia != null) links.add({'platform': 'Expedia', 'url': expedia!});
    if (airbnb != null) links.add({'platform': 'Airbnb', 'url': airbnb!});
    if (website != null) links.add({'platform': 'Website', 'url': website!});
    if (eventbrite != null) {
      links.add({'platform': 'Eventbrite', 'url': eventbrite!});
    }
    if (meetup != null) links.add({'platform': 'Meetup', 'url': meetup!});
    if (whatsapp != null) {
      links.add({
        'platform': 'WhatsApp',
        'url': 'https://wa.me/${whatsapp!.replaceAll(RegExp(r'[^0-9]'), '')}',
      });
    }
    if (telegram != null) links.add({'platform': 'Telegram', 'url': telegram!});
    if (wechat != null) links.add({'platform': 'WeChat', 'url': wechat!});
    return links;
  }

  bool get hasLinks => activeLinks.isNotEmpty;
}
