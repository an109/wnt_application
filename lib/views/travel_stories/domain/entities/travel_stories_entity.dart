import 'package:equatable/equatable.dart';

class TravelStoryEntity extends Equatable {
  final int id;
  final String? featuredImageUrl;
  final String? headerImageUrl;
  final String? image2Url;
  final String? image3Url;
  final String? ogImageUrl;
  final String? twitterImageUrl;
  final String? authorImageUrl;
  final String title;
  final String slug;
  final String content;
  final String? excerpt;
  final String? category;
  final String? tags;
  final String status;
  final String? publishDate;
  final String? metaTitle;
  final String? metaDescription;
  final String? canonicalUrl;
  final String? authorName;
  final String? authorBio; // <-- Added
  final int viewsCount;
  final String? createdAt;
  final String? updatedAt;

  const TravelStoryEntity({
    required this.id,
    this.featuredImageUrl,
    this.headerImageUrl,
    this.image2Url,
    this.image3Url,
    this.ogImageUrl,
    this.twitterImageUrl,
    this.authorImageUrl,
    required this.title,
    required this.slug,
    required this.content,
    this.excerpt,
    this.category,
    this.tags,
    required this.status,
    this.publishDate,
    this.metaTitle,
    this.metaDescription,
    this.canonicalUrl,
    this.authorName,
    this.authorBio, // <-- Added
    required this.viewsCount,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    featuredImageUrl,
    headerImageUrl,
    image2Url,
    image3Url,
    ogImageUrl,
    twitterImageUrl,
    authorImageUrl,
    title,
    slug,
    content,
    excerpt,
    category,
    tags,
    status,
    publishDate,
    metaTitle,
    metaDescription,
    canonicalUrl,
    authorName,
    authorBio, // <-- Added
    viewsCount,
    createdAt,
    updatedAt,
  ];
}