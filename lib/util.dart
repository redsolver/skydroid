//const dnsUrl = 'https://easyhandshake.com:8053';
import 'package:preferences/preferences.dart';


/* const dnsUrl = 'https://dns.nextdns.io/cb574e';
const skynetPortal = 'https://siasky.net'; */

String get dnsUrl => PrefService.getString('dnsUrl');
String get skynetPortal => PrefService.getString('skynetPortal');

String resolveLink(String apkLink) {
  if (apkLink.startsWith('sia://'))
    apkLink = skynetPortal + '/' + apkLink.substring(6);

  return apkLink;
}
