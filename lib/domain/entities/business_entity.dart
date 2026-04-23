import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Contact information for a business.
class ContactInfo extends Equatable {
  final String phone;
  final String email;
  final String whatsapp;

  const ContactInfo({
    this.phone = '',
    this.email = '',
    this.whatsapp = '',
  });

  ContactInfo copyWith({String? phone, String? email, String? whatsapp}) {
    return ContactInfo(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'email': email,
        'whatsapp': whatsapp,
      };

  factory ContactInfo.fromMap(Map<String, dynamic> map) => ContactInfo(
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        whatsapp: map['whatsapp'] ?? '',
      );

  @override
  List<Object?> get props => [phone, email, whatsapp];
}

/// Social media links for a business.
class SocialLinks extends Equatable {
  final String facebook;
  final String instagram;
  final String twitter;
  final String linkedin;

  const SocialLinks({
    this.facebook = '',
    this.instagram = '',
    this.twitter = '',
    this.linkedin = '',
  });

  SocialLinks copyWith({
    String? facebook,
    String? instagram,
    String? twitter,
    String? linkedin,
  }) {
    return SocialLinks(
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
    );
  }

  Map<String, dynamic> toMap() => {
        'facebook': facebook,
        'instagram': instagram,
        'twitter': twitter,
        'linkedin': linkedin,
      };

  factory SocialLinks.fromMap(Map<String, dynamic> map) => SocialLinks(
        facebook: map['facebook'] ?? '',
        instagram: map['instagram'] ?? '',
        twitter: map['twitter'] ?? '',
        linkedin: map['linkedin'] ?? '',
      );

  @override
  List<Object?> get props => [facebook, instagram, twitter, linkedin];
}

/// The business profile of the user.
class BusinessEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final BusinessCategory category;
  final String? logoPath;
  final ContactInfo contact;
  final SocialLinks socialLinks;

  const BusinessEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.logoPath,
    this.contact = const ContactInfo(),
    this.socialLinks = const SocialLinks(),
  });

  BusinessEntity copyWith({
    String? id,
    String? userId,
    String? name,
    BusinessCategory? category,
    String? logoPath,
    ContactInfo? contact,
    SocialLinks? socialLinks,
  }) {
    return BusinessEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      logoPath: logoPath ?? this.logoPath,
      contact: contact ?? this.contact,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, name, category, logoPath, contact, socialLinks];
}
