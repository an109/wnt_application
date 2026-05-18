import 'package:dio/dio.dart';

import '../../../../core/error/data_state.dart';
import '../../domain/entities/travel_stories_entity.dart';
import '../data_source/travel_stories_api_service.dart';
import '../../domain/repository/travel_stories_repository.dart';
import '../models/travel_stories_model.dart';

class TravelStoriesRepositoryImpl implements TravelStoriesRepository {
  final TravelStoriesApiService apiService;

  TravelStoriesRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<TravelStoryEntity>>> getTravelStories({
    String? status,
    String? domain,
    int? limit,
  }) async {
    try {
      final response = await apiService.getTravelStories(
        status: status,
        domain: domain,
        limit: limit,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['travel_stories'] != null) {
          final List<dynamic> storiesJson = data['travel_stories'];
          final List<TravelStoryModel> models = storiesJson
              .map((json) => TravelStoryModel.fromJson(json))
              .toList();

          final List<TravelStoryEntity> entities = models
              .map((model) => _modelToEntity(model))
              .toList();

          return DataSuccess(entities);
        } else {
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Invalid response format',
              type: DioExceptionType.badResponse,
            ),
          );
        }
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to load travel stories',
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<TravelStoryEntity>> getTravelStoryBySlug(String slug) async {
    try {
      // Fetch all stories from the list endpoint
      final response = await apiService.getTravelStories(
        status: 'published',
        domain: 'thewandernova.com',
        limit: 50, // Fetch enough to include the target story
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['travel_stories'] != null) {
          final List<dynamic> storiesJson = data['travel_stories'];

          // Find the story matching the slug
          final targetStoryJson = storiesJson.firstWhere(
                (json) => json['slug'] == slug,
            orElse: () => null,
          );

          if (targetStoryJson != null) {
            final TravelStoryModel model = TravelStoryModel.fromJson(targetStoryJson);
            final TravelStoryEntity entity = _modelToEntity(model);
            return DataSuccess(entity);
          } else {
            return  DataFailed(
              DioException(
                requestOptions: RequestOptions(path: ''),
                error: 'Story not found with slug: $slug',
                type: DioExceptionType.badResponse,
              ),
            );
          }
        } else {
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Invalid response format',
              type: DioExceptionType.badResponse,
            ),
          );
        }
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to load travel stories',
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  TravelStoryEntity _modelToEntity(TravelStoryModel model) {
    return TravelStoryEntity(
      id: model.id,
      featuredImageUrl: model.featuredImageUrl,
      headerImageUrl: model.headerImageUrl,
      image2Url: model.image2Url,
      image3Url: model.image3Url,
      ogImageUrl: model.ogImageUrl,
      twitterImageUrl: model.twitterImageUrl,
      authorImageUrl: model.authorImageUrl,
      title: model.title,
      slug: model.slug,
      content: model.content,
      excerpt: model.excerpt,
      category: model.category,
      tags: model.tags,
      status: model.status,
      publishDate: model.publishDate,
      metaTitle: model.metaTitle,
      metaDescription: model.metaDescription,
      canonicalUrl: model.canonicalUrl,
      authorName: model.authorName,
      viewsCount: model.viewsCount,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}