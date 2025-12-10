// Web 平台实现
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 获取浏览器当前 URL
String getWindowLocationHref() {
  return html.window.location.href;
}
