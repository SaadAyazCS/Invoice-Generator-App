import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareFile(String filePath, {String? text, String? subject}) async {
    final file = XFile(filePath);
    await Share.shareXFiles(
      [file],
      text: text ?? 'Invoice document attached.',
      subject: subject ?? 'Invoice',
    );
  }

  static Future<void> shareBytes(List<int> bytes, String fileName, {String? text, String? subject}) async {
    final xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      name: fileName,
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles(
      [xFile],
      text: text ?? 'Invoice document attached.',
      subject: subject ?? 'Invoice',
    );
  }
}
