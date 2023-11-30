import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:dlna_player/application.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/theme_options.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: ThemeProvider.optionsOf<ThemeOptions>(context)
            .drawerDecoration(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: ThemeProvider.optionsOf<ThemeOptions>(context)
                  .drawerHeaderDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DLNA Player',
                      textScaler: TextScaler.linear(1.6),
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (ctx, snapshot) {
                          var defText = '---';
                          if (snapshot.hasData) {
                            defText =
                                '${snapshot.data!.version}+${snapshot.data!.buildNumber}';
                          }
                          return Text(
                              i18n(context).com_drawer_version(defText));
                        }),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(i18n(context).com_change_theme),
              onTap: () {
                ThemeProvider.controllerOf(context).nextTheme();
              },
              leading: const Icon(
                Icons.color_lens,
              ),
            ),
            ListTile(
              title: Text(i18n(context).com_change_language),
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
