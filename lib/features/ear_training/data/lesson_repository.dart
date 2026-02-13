import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/api_client.dart';
import '../models/lesson_config.dart';
import '../models/level_model.dart';

class LessonRepository {
  final ApiClient _apiClient;

  LessonRepository(this._apiClient);

  Future<List<Level>> getLevels() async {
    try {
      final response = await _apiClient.dio.get('/api/curriculum'); // API route is /curriculum for list
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Level.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load levels');
      }
    } catch (e) {
      throw Exception('Error loading levels: $e');
    }
  }

  Future<LessonConfig> getLessonConfig(int levelId) async {
    try {
      final response = await _apiClient.dio.get('/api/levels/$levelId');
      // The API returns the Level object, which has a 'config' field
      if (response.statusCode == 200) {
        return LessonConfig.fromJson(response.data['config']);
      } else {
        throw Exception('Failed to load lesson config');
      }
    } catch (e) {
      throw Exception('Error loading lesson config: $e');
    }
  }

  Future<List<NoteAudio>> getNoteAudioList(int octave) async {
    try {
      // Fetch notes for the specific octave
      final response = await _apiClient.dio.get('/api/notes', queryParameters: {'octave': octave});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => NoteAudio.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      throw Exception('Error loading notes: $e');
    }
  }

  Future<bool> deductLife() async {
    try {
      final response = await _apiClient.dio.post('/api/gamification/deduct-life');
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // If 400 (no lives), we treat it as successfully "failed to deduct" or just return false
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRanking({String? league}) async {
    try {
      final response = await _apiClient.dio.get('${ApiClient.baseUrl}/api/gamification/ranking', queryParameters: {
        'league': league
      });

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load ranking');
      }
    } catch (e) {
      throw Exception('Failed to load ranking: $e');
    }
  }

  Future<Map<String, dynamic>> completePractice() async {
    try {
      final response = await _apiClient.dio.post('/api/gamification/practice-complete');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to complete practice');
      }
    } catch (e) {
      throw Exception('Error completing practice: $e');
    }
  }

  Future<dynamic> getUser() async {
     try {
       final response = await _apiClient.dio.get('/api/user');
       return response.data;
     } catch (e) {
       throw Exception('Failed to load user');
     }
  }

  Future<String> downloadAudio(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      if (await file.exists()) {
        return file.path;
      }

      String downloadUrl = url;
      if (!url.startsWith('http')) {
         if (url.startsWith('/')) {
             downloadUrl = '${ApiClient.baseUrl}$url';
         } else {
             downloadUrl = '${ApiClient.baseUrl}/$url';
         }
      }
      
      // Ensure special characters like '#' are properly encoded
      // Note: Full URL encoding might double encode, so handle carefully.
      // Usually, just replacing # fixes the most common issue with sharps.
      downloadUrl = downloadUrl.replaceAll('#', '%23');

      // API headers (e.g. Accept: application/json) on static assets.
      final dio = Dio(); 
      await dio.download(downloadUrl, file.path);
      return file.path;
    } catch (e) {
      throw Exception('Error downloading audio: $e');
    }
  }
}
