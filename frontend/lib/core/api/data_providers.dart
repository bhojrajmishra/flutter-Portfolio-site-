import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/about_content.dart';
import '../models/apk_file.dart';
import '../models/blog_post.dart';
import '../models/contact_message.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/hero_content.dart';
import '../models/project.dart';
import '../models/resume_file.dart';
import '../models/site_settings.dart';
import '../models/skill.dart';
import '../models/social_link.dart';
import '../models/weather.dart';
import 'portfolio_repository.dart';
import 'weather_repository.dart';

// Each provider fetches once and caches; call `ref.invalidate(xProvider)`
// after an admin write to refetch and propagate the update to every listener
// (including the public page, if it's mounted in the same app instance).

final heroProvider = FutureProvider<HeroContent>((ref) {
  return ref.watch(portfolioRepositoryProvider).getHero();
});

final aboutProvider = FutureProvider<AboutContent>((ref) {
  return ref.watch(portfolioRepositoryProvider).getAbout();
});

final skillsProvider = FutureProvider<List<Skill>>((ref) {
  return ref.watch(portfolioRepositoryProvider).getSkills();
});

final projectsProvider = FutureProvider<List<Project>>((ref) {
  return ref.watch(portfolioRepositoryProvider).getProjects();
});

final experienceProvider = FutureProvider<List<Experience>>((ref) {
  return ref.watch(portfolioRepositoryProvider).getExperience();
});

final educationProvider = FutureProvider<List<Education>>((ref) {
  return ref.watch(portfolioRepositoryProvider).getEducation();
});

final socialLinksProvider = FutureProvider<List<SocialLink>>((ref) {
  return ref.watch(portfolioRepositoryProvider).getSocialLinks();
});

final resumeProvider = FutureProvider<ResumeFile?>((ref) {
  return ref.watch(portfolioRepositoryProvider).getResume();
});

final contactMessagesProvider = FutureProvider<List<ContactMessage>>((ref) {
  return ref.watch(portfolioRepositoryProvider).getContactMessages();
});

final settingsProvider = FutureProvider<SiteSettings>((ref) {
  return ref.watch(portfolioRepositoryProvider).getSettings();
});

final blogPostsProvider = FutureProvider<List<BlogPost>>((ref) {
  return ref.watch(portfolioRepositoryProvider).getBlogPosts();
});

final apkProvider = FutureProvider<ApkFile?>((ref) {
  return ref.watch(portfolioRepositoryProvider).getApk();
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) => WeatherRepository());

/// Live weather for the admin-configured location. Chained off
/// [settingsProvider]; UI should treat a failure here as non-fatal (show
/// "weather unavailable") since it's a decorative feature.
final weatherProvider = FutureProvider<Weather>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return ref.watch(weatherRepositoryProvider).getCurrentWeather(
        lat: settings.weatherLat,
        lon: settings.weatherLon,
      );
});

/// Invalidates every public-content provider — call after any admin write.
void invalidateAllContent(WidgetRef ref) {
  ref.invalidate(heroProvider);
  ref.invalidate(aboutProvider);
  ref.invalidate(skillsProvider);
  ref.invalidate(projectsProvider);
  ref.invalidate(experienceProvider);
  ref.invalidate(educationProvider);
  ref.invalidate(socialLinksProvider);
  ref.invalidate(resumeProvider);
  ref.invalidate(settingsProvider);
  ref.invalidate(blogPostsProvider);
  ref.invalidate(apkProvider);
}
