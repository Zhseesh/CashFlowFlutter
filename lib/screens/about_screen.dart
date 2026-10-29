import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _checking = false;

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/Zhseesh/CashFlowFlutter/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Flutter-CashFlow-App',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final htmlUrl = data['html_url'].toString();
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;

        if (latestVersion != currentVersion) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.translate('update_available')),
              content: Text('${l10n.translate('update_msg')} $currentVersion'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('later'))),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse(htmlUrl), mode: LaunchMode.externalApplication);
                  },
                  child: Text(l10n.translate('open_github')),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.translate('up_to_date')),
              content: Text('${l10n.translate('up_to_date_msg')} ($currentVersion).'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('close')))],
            ),
          );
        }
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.translate('info')),
            content: Text(l10n.translate('no_release')),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('close')))],
          ),
        );
      } else {
        throw Exception('Server merespon dengan kode ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('error_update'))),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('about'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.account_balance_wallet, size: 48, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 24),
              const Text('Cash Flow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('${l10n.translate('version')} ${snapshot.data!.version}+${snapshot.data!.buildNumber}', style: TextStyle(color: Colors.grey.shade500));
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _checkUpdate,
                  icon: _checking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.system_update),
                  label: Text(_checking ? l10n.translate('checking') : l10n.translate('check_update')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('made_with'),
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              )
            ],
          ),
        ),
      ),
    );
  }
}