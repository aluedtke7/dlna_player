import 'package:dlna_player/application.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:theme_provider/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: ThemeProvider.optionsOf<ThemeOptions>(context).drawerDecoration(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: ThemeProvider.optionsOf<ThemeOptions>(context).drawerHeaderDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DLNA Player', textScaleFactor: 1.6, style: TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (ctx, snapshot) {
                          var defText = '---';
                          if (snapshot.hasData) {
                            defText = '${snapshot.data!.version}+${snapshot.data!.buildNumber}';
                          }
                          return Text(AppLocalizations.of(context)?.com_drawer_version(defText) ?? '');
                        }),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)?.com_change_theme ?? ''),
              onTap: () {
                ThemeProvider.controllerOf(context).nextTheme();
              },
              leading: const Icon(
                Icons.color_lens,
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)?.com_change_language ?? ''),
              onTap: () {
                if ((Intl.defaultLocale ?? '').contains('de')) {
                  Intl.defaultLocale = 'en';
                  APPLIC().onLocaleChanged(const Locale('en', ''));
                } else {
                  Intl.defaultLocale = 'de';
                  APPLIC().onLocaleChanged(const Locale('de', ''));
                }
              },
              leading: const Icon(
                Icons.language,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
