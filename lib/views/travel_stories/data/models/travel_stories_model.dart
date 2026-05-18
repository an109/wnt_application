class TravelStoryModel {
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
  final int viewsCount;
  final String? createdAt;
  final String? updatedAt;

  TravelStoryModel({
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
    required this.viewsCount,
    this.createdAt,
    this.updatedAt,
  });

  factory TravelStoryModel.fromJson(Map<String, dynamic> json) {
    return TravelStoryModel(
      id: json['id'] ?? 0,
      featuredImageUrl: json['featured_image_url'],
      headerImageUrl: json['header_image_url'],
      image2Url: json['image_2_url'],
      image3Url: json['image_3_url'],
      ogImageUrl: json['og_image_url'],
      twitterImageUrl: json['twitter_image_url'],
      authorImageUrl: json['author_image_url'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      excerpt: json['excerpt'],
      category: json['category'],
      tags: json['tags'],
      status: json['status'] ?? '',
      publishDate: json['publish_date'],
      metaTitle: json['meta_title'],
      metaDescription: json['meta_description'],
      canonicalUrl: json['canonical_url'],
      authorName: json['author_name'],
      viewsCount: json['views_count'] ?? 0,
      createdAt: json['created'],
      updatedAt: json['updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'featured_image_url': featuredImageUrl,
      'header_image_url': headerImageUrl,
      'image_2_url': image2Url,
      'image_3_url': image3Url,
      'og_image_url': ogImageUrl,
      'twitter_image_url': twitterImageUrl,
      'author_image_url': authorImageUrl,
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'category': category,
      'tags': tags,
      'status': status,
      'publish_date': publishDate,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'canonical_url': canonicalUrl,
      'author_name': authorName,
      'views_count': viewsCount,
      'created': createdAt,
      'updated': updatedAt,
    };
  }
}