import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/about_content.dart';
import '../models/contact_message.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/hero_content.dart';
import '../models/project.dart';
import '../models/resume_file.dart';
import '../models/site_settings.dart';
import '../models/skill.dart';
import '../models/social_link.dart';
import 'auth_controller.dart';

/// Thin wrapper around every backend endpoint. Public GETs are usable
/// without auth; the write methods require the admin to be logged in
/// (the underlying Dio instance attaches the bearer token automatically).
class PortfolioRepository {
  final Dio _dio;
  PortfolioRepository(this._dio);

  // ---- Hero ----
  Future<HeroContent> getHero() async {
    final res = await _dio.get('/hero');
    return HeroContent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateHero(HeroContent hero) => _dio.put('/hero', data: hero.toJson());

  // ---- About ----
  Future<AboutContent> getAbout() async {
    final res = await _dio.get('/about');
    return AboutContent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateAbout(AboutContent about) => _dio.put('/about', data: about.toJson());

  // ---- Skills ----
  Future<List<Skill>> getSkills() async {
    final res = await _dio.get('/skills');
    return (res.data as List).map((e) => Skill.fromJson(e)).toList();
  }

  Future<void> createSkill(Skill skill) => _dio.post('/skills', data: skill.toJson());
  Future<void> updateSkill(Skill skill) => _dio.put('/skills/${skill.id}', data: skill.toJson());
  Future<void> deleteSkill(int id) => _dio.delete('/skills/$id');

  // ---- Projects ----
  Future<List<Project>> getProjects() async {
    final res = await _dio.get('/projects');
    return (res.data as List).map((e) => Project.fromJson(e)).toList();
  }

  Future<void> createProject(Project project) => _dio.post('/projects', data: project.toJson());
  Future<void> updateProject(Project project) =>
      _dio.put('/projects/${project.id}', data: project.toJson());
  Future<void> deleteProject(int id) => _dio.delete('/projects/$id');

  // ---- Experience ----
  Future<List<Experience>> getExperience() async {
    final res = await _dio.get('/experience');
    return (res.data as List).map((e) => Experience.fromJson(e)).toList();
  }

  Future<void> createExperience(Experience e) => _dio.post('/experience', data: e.toJson());
  Future<void> updateExperience(Experience e) =>
      _dio.put('/experience/${e.id}', data: e.toJson());
  Future<void> deleteExperience(int id) => _dio.delete('/experience/$id');

  // ---- Education ----
  Future<List<Education>> getEducation() async {
    final res = await _dio.get('/education');
    return (res.data as List).map((e) => Education.fromJson(e)).toList();
  }

  Future<void> createEducation(Education e) => _dio.post('/education', data: e.toJson());
  Future<void> updateEducation(Education e) => _dio.put('/education/${e.id}', data: e.toJson());
  Future<void> deleteEducation(int id) => _dio.delete('/education/$id');

  // ---- Social links ----
  Future<List<SocialLink>> getSocialLinks() async {
    final res = await _dio.get('/social-links');
    return (res.data as List).map((e) => SocialLink.fromJson(e)).toList();
  }

  Future<void> upsertSocialLink(String platform, String url, {String? badgeText}) => _dio.put(
        '/social-links/$platform',
        data: {'url': url, 'badgeText': badgeText},
      );
  Future<void> deleteSocialLink(String platform) => _dio.delete('/social-links/$platform');

  // ---- Resume ----
  Future<ResumeFile?> getResume() async {
    final res = await _dio.get('/resume');
    if (res.data == null) return null;
    return ResumeFile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ResumeFile> uploadResume(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post('/resume', data: formData);
    return ResumeFile.fromJson(res.data as Map<String, dynamic>);
  }

  // ---- Image upload (hero background, project thumbnails) ----
  Future<String> uploadImage(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post('/uploads/image', data: formData);
    return res.data['url'] as String;
  }

  // ---- Contact ----
  Future<void> sendContactMessage({
    required String name,
    required String email,
    required String message,
  }) =>
      _dio.post('/contact', data: {'name': name, 'email': email, 'message': message});

  Future<List<ContactMessage>> getContactMessages() async {
    final res = await _dio.get('/contact');
    return (res.data as List).map((e) => ContactMessage.fromJson(e)).toList();
  }

  Future<void> markContactMessageRead(int id) => _dio.put('/contact/$id/read');
  Future<void> deleteContactMessage(int id) => _dio.delete('/contact/$id');

  // ---- Site settings (weather location) ----
  Future<SiteSettings> getSettings() async {
    final res = await _dio.get('/settings');
    return SiteSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateSettings(SiteSettings settings) =>
      _dio.put('/settings', data: settings.toJson());
}

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository(ref.watch(dioProvider));
});
