import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/neo_theme.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/neo_toast.dart';

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
        Uri.parse(
            'https://api.github.com/repos/Zhseesh/CashFlowFlutter/releases/latest'),
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
          showNeoDialog(
            context: context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoDialogTitle(l10n.translate('update_available')),
                Text('${l10n.translate('update_msg')} $currentVersion',
                    style: NeoText.body(13, color: Neo.ink(context))),
                NeoDialogActions(
                  children: [
                    NeoButton(
                      label: l10n.translate('later'),
                      variant: NeoButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    NeoButton(
                      label: l10n.translate('open_github'),
                      onPressed: () {
                        Navigator.pop(context);
                        launchUrl(Uri.parse(htmlUrl),
                            mode: LaunchMode.externalApplication);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          showNeoDialog(
            context: context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoDialogTitle(l10n.translate('up_to_date')),
                Text('${l10n.translate('up_to_date_msg')} ($currentVersion).',
                    style: NeoText.body(13, color: Neo.ink(context))),
                NeoDialogActions(
                  children: [
                    NeoButton(
                      label: l10n.translate('close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        showNeoDialog(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeoDialogTitle(l10n.translate('info')),
              Text(l10n.translate('no_release'),
                  style: NeoText.body(13, color: Neo.ink(context))),
              NeoDialogActions(
                children: [
                  NeoButton(
                    label: l10n.translate('close'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        throw Exception('Server merespon dengan kode ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      NeoToast.show(context, (l10n.translate('error_update')));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('about'),
            style: NeoText.display(18, color: ink)),
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
                  color: NeoColors.yellow,
                  borderRadius: BorderRadius.circular(24),
                  border: NeoBorders.thick(ink),
                  boxShadow: NeoShadows.md(ink),
                ),
                child: Icon(LucideIcons.wallet, size: 48,
                    color: NeoColors.inkLight),
              ),
              const SizedBox(height: 24),
              Text('CASH FLOW', style: NeoText.display(24, color: ink)),
              const SizedBox(height: 8),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      '${l10n.translate('version')} ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                      style: NeoText.label(11,
                          color: ink.withValues(alpha: 0.6)),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 40),
              NeoButton(
                label: _checking
                    ? l10n.translate('checking')
                    : l10n.translate('check_update'),
                icon: LucideIcons.download,
                loading: _checking,
                expanded: true,
                onPressed: _checking ? null : _checkUpdate,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('made_with'),
                style: NeoText.body(11, color: ink.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}