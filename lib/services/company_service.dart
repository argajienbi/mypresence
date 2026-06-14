import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import '../core/utils.dart';
import 'rtdb_service.dart';

class CompanyWebsiteConfig {
  final bool enabled;
  final String title;
  final String url;
  final List<String> allowedDomains;

  const CompanyWebsiteConfig({
    required this.enabled,
    required this.title,
    required this.url,
    required this.allowedDomains,
  });

  bool get available => enabled && url.trim().isNotEmpty;

  Uri? get uri {
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null || !parsed.hasScheme || parsed.scheme.toLowerCase() != 'https') return null;
    return parsed;
  }

  bool isAllowed(Uri uri) {
    if (uri.scheme.toLowerCase() != 'https') return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    if (allowedDomains.isEmpty) return uri == this.uri || host == this.uri?.host.toLowerCase();
    return allowedDomains.map((e) => e.toLowerCase().trim()).where((e) => e.isNotEmpty).any((domain) => host == domain || host.endsWith('.$domain'));
  }
}

class CompanyBrandingConfig {
  final String companyName;
  final bool logoEnabled;
  final String logoUrl;
  final String logoPath;

  const CompanyBrandingConfig({
    required this.companyName,
    required this.logoEnabled,
    required this.logoUrl,
    required this.logoPath,
  });

  bool get hasLogo => logoEnabled && logoUrl.trim().isNotEmpty;
}

class CompanyService {
  final RtdbService _rtdb = RtdbService();

  Future<CompanyWebsiteConfig> loadWebsiteConfig(AppSession session) async {
    final company = await _rtdb.getMap(FirebasePaths.company(session.companyId));
    final domainsRaw = company?['company_allowed_domains'];
    final domains = <String>[];
    if (domainsRaw is List) {
      domains.addAll(domainsRaw.map((e) => e.toString()));
    } else if (domainsRaw is Map) {
      domains.addAll(domainsRaw.values.map((e) => e.toString()));
    }

    final url = asString(company?['company_website_url']);
    final parsed = Uri.tryParse(url);
    if (parsed != null && parsed.host.isNotEmpty && domains.isEmpty) {
      domains.add(parsed.host);
    }

    return CompanyWebsiteConfig(
      enabled: company?['company_website_enabled'] == true || asString(company?['company_website_enabled']) == 'true',
      title: asString(company?['company_website_title'], 'Website Perusahaan'),
      url: url,
      allowedDomains: domains,
    );
  }

  Future<CompanyBrandingConfig> loadBrandingConfig(AppSession session) async {
    final company = await _rtdb.getMap(FirebasePaths.company(session.companyId));

    final companyName = asString(
      company?['display_name'],
      asString(
        company?['name'],
        asString(company?['company_name'], 'MYPRESENCE'),
      ),
    );

    return CompanyBrandingConfig(
      companyName: companyName.trim().isEmpty ? 'MYPRESENCE' : companyName.trim(),
      logoEnabled: company?['company_logo_enabled'] == true ||
          asString(company?['company_logo_enabled']) == 'true',
      logoUrl: asString(company?['company_logo_url']),
      logoPath: asString(company?['company_logo_path']),
    );
  }
}
