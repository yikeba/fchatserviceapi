import 'dart:async';
import 'dart:convert';
import 'dart:html' as html show FileUploadInputElement, File, FileReader, window;
import 'dart:typed_data';
import 'package:fchatapi/Util/PhoneUtil.dart';
import 'package:fchatapi/appapi/ServiceUrl.dart';
import 'package:fchatapi/webapi/ShortUrl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_web/image_picker_web.dart';

import '../../QuickAlertShow.dart';

/// Short Link Generator Widget
/// - Paste a full URL
/// - Upload an image (Flutter web)
/// - Enter short-link name (slug)
/// - Enter price
///
/// Usage: place ShortLinkGenerator() inside your Flutter web app.
class ShortLinkGenerator extends StatefulWidget {
  const ShortLinkGenerator({super.key});

  @override
  _ShortLinkGeneratorState createState() => _ShortLinkGeneratorState();
}

class _ShortLinkGeneratorState extends State<ShortLinkGenerator> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;
  String? _generatedShortUrl;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImageWeb() async {
    if (!kIsWeb) return;
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        setState(() {
          _imageBytes = reader.result is Uint8List
              ? reader.result as Uint8List
              : Uint8List.view((reader.result as ByteBuffer));
          _imageName = file.name;
        });
      });
    });
  }


  String _generateSlug([int len = 6]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rnd = DateTime.now().millisecondsSinceEpoch;
    final sb = StringBuffer();
    var state = rnd;
    for (var i = 0; i < len; i++) {
      state = (state * 48271) % 2147483647; // simple LCG
      sb.write(chars[state % chars.length]);
    }
    return sb.toString();
  }

  Uint8List? _selectedImageBytes;
  String? _selectedImageBase64;

  Future<void> _pickImage() async {
    final result = await ImagePickerWeb.getImageAsBytes();
    if (result != null) {
      setState(() {
        _selectedImageBytes = result;
        _selectedImageBase64 = base64Encode(result);
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _generatedShortUrl = null;
    });

    final originalUrl = _urlController.text.trim();
    var slug = _nameController.text.trim();
    final price = _priceController.text;

    if (slug.isEmpty) {
      slug = _generateSlug();
    }

    // 构造短链对象
    ServiceUrl shorturl = ServiceUrl(originalUrl, slug);
    shorturl.price = price.toString();

    // ✅ 使用上传的图片 base64
    if (_selectedImageBase64 != null && _selectedImageBase64!.isNotEmpty) {
      shorturl.image = _selectedImageBase64!;
      PhoneUtil.applog("fchat api 图片 base64 长度: ${shorturl.image.length}");
    } else {
      PhoneUtil.applog("未选择图片");
    }

    try {
      Map map = await ShortUrl.creatShortUrl(shorturl);
      String recshorturl = "";
      if (map.containsKey(originalUrl)) {
        recshorturl = map[originalUrl];
        QuickAlertShow.showCopyinfo(context, "ShortUrl", recshorturl);
      }
      setState(() {
        _generatedShortUrl = recshorturl;
      });
    } catch (e) {
      PhoneUtil.applog("短链创建失败: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }


  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (kIsWeb) {
        // show browser native toast? we just show snackbar
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制失败: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('短链接生成器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // URL input
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: '原始链接 (https://...)',
                      hintText: 'https://your-domain.com/xxx',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '请输入 URL';
                      final val = v.trim();
                      if (!val.startsWith('http://') && !val.startsWith('https://')) {
                        return '请以 http:// 或 https:// 开头';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Image upload row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('上传图片'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _imageBytes == null
                            ? const Text('未上传图片（可选）')
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_imageName ?? 'image'),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: Image.memory(_imageBytes!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Name (slug)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '短链接名称（可空，留空则自动生成）',
                      hintText: '例如: summer-sale',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: '价格 (数字，单位: USD)',
                      hintText: '例如: 9.99',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // price optional
                      final p = double.tryParse(v.trim());
                      if (p == null) return '请输入有效数字';
                      if (p < 0) return '价格不能为负数';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Submit
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onSubmit,
                          child: _loading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('生成短链接'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_generatedShortUrl != null) ...[
              SelectableText('短链接: ' + _generatedShortUrl!, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(_generatedShortUrl!),
                    icon: const Icon(Icons.copy),
                    label: const Text('复制链接'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Open the short url in a new tab (web only)
                      if (kIsWeb) html.window.open(_generatedShortUrl!, '_blank');
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('打开预览'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
