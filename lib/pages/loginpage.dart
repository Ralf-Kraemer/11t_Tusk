import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:wecq/pages/homepage.dart';

import '../state/objects/ApiOAuth.dart';
import '../utils/helper.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showLoginFields = false;
  bool error = false;
  String url = 'https://fosstodon.org';
  ApiOAuth api = ApiOAuth();
  Helper helper = Helper.get();

  @override
  void initState() {
    super.initState();
    handleInitialDeepLink(); // Look for code on startup
    checkLoginStatus();
  }

  void handleInitialDeepLink() async {
    final uri = Uri.base; // e.g., wecq://wecq.social?code=abc123
    if (uri.scheme == 'wecq' && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      if (code != null) {
        await api.exchangeCodeForTokens(code);
        navigateToTimeline();
      }
    }
  }

  void checkLoginStatus() async {
    var access_token = await api.maybeRefreshAccessToken();
    print("Access token: $access_token");
    if (access_token == null) {
      setState(() {
        showLoginFields = true;
      });
    } else {
      navigateToTimeline();
    }
  }

  void prepareLogin(String? _url) async {
    try {
      await api.setBaseUrl(_url ?? url);
      await api.fetchClientIdSecret();
      var redirectUrl = await api.getRedirectUrl();
      openOAuthScreen(redirectUrl);
      helper.setHomeInstanceName(_url ?? url);
    } catch (e) {
      setState(() {
        error = true;
      });
    }
  }

  void openOAuthScreen(String url) {
    FlutterWebBrowser.openWebPage(
      url: url,
      customTabsOptions: CustomTabsOptions(
        shareState: CustomTabsShareState.on,
        instantAppsEnabled: true,
        showTitle: true,
        urlBarHidingEnabled: true,
      ),
      safariVCOptions: SafariViewControllerOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        modalPresentationCapturesStatusBarAppearance: true,
      ),
    );
  }

  void navigateToTimeline() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HomePage(),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  return Scaffold(
    body: showLoginFields
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LogoLoading(),

                SizedBox(
                  height: 48,
                  child: Text(
                    "WeCQ",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () => prepareLogin("https://wecq.social"),
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStatePropertyAll(cs.primary),
                  ),
                  child: Text(
                    '🌼 Connect with wecq.social',
                    style: TextStyle(
                      fontSize: 18,
                      color: cs.onPrimary,
                    ),
                  ),
                ),

                SizedBox(
                  height: 36,
                  child: Text(
                    "OR",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                DropdownMenu(
                    textAlign: TextAlign.justify,
                    hintText: "Select instance",
                    // label: Text("Pick a server", textAlign: TextAlign.center,),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: "https://mastodon.social", label: "🦣#️⃣1️⃣ Mastodon.social"),
                      DropdownMenuEntry(value: "https://mastodon.top", label: "🇫🇷🇬🇧🇪🇺 Mastodon.top"),
                      DropdownMenuEntry(value: "https://kolektiva.social", label: "🏴☮️ Kolektiva.social"),
                      DropdownMenuEntry(value: "https://troet.cafe", label: "🇩🇪 Troet Café"),
                      DropdownMenuEntry(value: "https://Mastodon.nl", label: "🇳🇱 Mastodon NL"),
                      DropdownMenuEntry(value: "https://mastodontti.fi", label: "🇫🇮 Mastodontti FI"),
                      DropdownMenuEntry(value: "https://mastodon.pt", label: "🇵🇹🇧🇷 Mastodon PT"),
                      DropdownMenuEntry(value: "https://mamot.fr", label: "🇮🇹 Mastodon.uno"),
                      DropdownMenuEntry(value: "https://mastodonapp.uk", label: "🇬🇧 Mastodon App UK"),
                      DropdownMenuEntry(value: "https://mastouille.fr", label: "🇫🇷 Mastouille.fr"),
                      DropdownMenuEntry(value: "https://mstdn.ca", label: "🇨🇦 Mstdn.ca"),
                      DropdownMenuEntry(value: "https://berlin.social", label: "🇩🇪🇪🇺 Berlin.social"),
                      DropdownMenuEntry(value: "https://muenchen.social", label: "🇩🇪🇪🇺 Muenchen.social"),
                      DropdownMenuEntry(value: "https://norden.social", label: "🇩🇪🇪🇺 Norden.social"),
                      DropdownMenuEntry(value: "https://social.cologne", label: "🇩🇪🇪🇺 Social.Cologne"),
                      DropdownMenuEntry(value: "https://hessen.social", label: "🇩🇪🇪🇺 Hessen.social"),
                      DropdownMenuEntry(value: "https://fulda.social", label: "🇩🇪🇪🇺 Fulda.social"),
                      DropdownMenuEntry(value: "https://muenster.im", label: "🇩🇪🇪🇺 Muenster.im"),
                      DropdownMenuEntry(value: "https://dresden.network", label: "🇩🇪🇪🇺 Dresden.network"),
                      DropdownMenuEntry(value: "https://leipzig.town", label: "🇩🇪🇪🇺 Leipzig.town"),
                      DropdownMenuEntry(value: "https://aus.social", label: "🇦🇺🇳🇿 Aus.social (+Oceania)"),
                      DropdownMenuEntry(value: "https://mastodon.com.tr", label: "🇹🇷 Mastodon Türkiye"),
                      DropdownMenuEntry(value: "https://mastodon.scot", label: "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Mastodon.scot"),
                      DropdownMenuEntry(value: "https://sfba.social", label: "🇺🇸 SF Bay Area (+California)"),
                      DropdownMenuEntry(value: "https://glasgow.social", label: "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Glasgow.social"),
                      DropdownMenuEntry(value: "https://mastodon.london", label: "🇬🇧 Mastodon.london"),
                      DropdownMenuEntry(value: "https://mamot.fr", label: "🇫🇷 Ma mot FR"),
                      DropdownMenuEntry(value: "https://piaille.fr", label: "🇫🇷 Piaille.fr"),
                      DropdownMenuEntry(value: "https://tkz.one", label: "🇪🇸🇲🇽🇨🇴🇦🇷 TKZ.One"),
                      DropdownMenuEntry(value: "https://fosstodon.org", label: "💻⚛️ FOSStodon"),
                      DropdownMenuEntry(value: "https://mastodon.cloud", label: "🦣☁️ Mastodon.cloud"),
                      DropdownMenuEntry(value: "https://mastodon.online", label: "🦣🛜 Mastodon.online"),
                      DropdownMenuEntry(value: "https://mastodon.world", label: "🦣🌍 Mastodon.world"),
                      DropdownMenuEntry(value: "https://mastodon.party", label: "🦣✨ Mastodon.party"),
                      DropdownMenuEntry(value: "https://mastodon.lol", label: "🦣🏳️‍🌈 Mastodon.lol"),
                      DropdownMenuEntry(value: "https://mas.to", label: "🦣 Mas.to"),
                      DropdownMenuEntry(value: "https://mstdn.social", label: "🐘 Mstdn.social"),
                      DropdownMenuEntry(value: "https://pixelfed.social", label: "📸 Pixelfed"),
                      DropdownMenuEntry(value: "https://octodon.social", label: "🏴‍☠️🏳️‍🌈 Octodon.social"),
                      DropdownMenuEntry(value: "https://universeodon.com", label: "🛸 Universeodon.com"),
                      DropdownMenuEntry(value: "https://social.tchncs.de", label: "🇩🇪⚙️ Tchncs"),
                      DropdownMenuEntry(value: "https://bark.lgbt", label: "🐕🏳️‍🌈 Bark!"),
                      DropdownMenuEntry(value: "https://mastodon.art", label: "🎨🖌️🎭 Mastodon.ART"),
                      DropdownMenuEntry(value: "https://mstdn.games", label: "🕹️👾 mstdn.games"),
                      DropdownMenuEntry(value: "https://mastodon.gamedev.place", label: "💻👾 GameDev Mastodon"),
                      DropdownMenuEntry(value: "https://tech.lgbt", label: "🏳️‍🌈LGBTQIA+ in Tech"),
                      DropdownMenuEntry(value: "https://infosec.exchange", label: "🛜🔓 Infosec Exchange"),
                      DropdownMenuEntry(value: "https://newsie.social", label: "📰🖋️ Newsie.social (4th Estate)"),
                      DropdownMenuEntry(value: "https://econtwitter.net", label: "🏦🐥 Econ Tw**ter"),
                      DropdownMenuEntry(value: "https://poa.st", label: "💩🤡 Poast"),
                      DropdownMenuEntry(value: "https://noc.social", label: "💻⚙️ Noc.social (Tech)"),
                      DropdownMenuEntry(value: "https://mastodon.eus", label: "Mastodon Euskara (Basque)"),
                      DropdownMenuEntry(value: "https://nafo.uk", label: "🇬🇧💕🇺🇦💕🇪🇺 NAFO.uk"),
                    ],
                    onSelected: (value) {
                      prepareLogin(value);
                    },
                  ),

                SizedBox(
                  height: 36,
                  child: Text(
                    "OR",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: TextField(
                    onChanged: (value) => url = value,
                    textInputAction: TextInputAction.go,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Enter URL here',
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                ElevatedButton(
                  onPressed: () => prepareLogin(url),
                  child: const Text('Connect'),
                ),
              ],
            ),
          )
        : const Center(child: LogoLoading()),
  );
}
}

class LogoLoading extends StatelessWidget {
  const LogoLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 150.0,
      width: 150.0,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        image: const DecorationImage(
          image: AssetImage('assets/images/logo-wecq.png'),
          fit: BoxFit.fill,
        ),
        border: Border.all(
          color: cs.onPrimaryContainer,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(75.0),
      ),
    );
  }
}

